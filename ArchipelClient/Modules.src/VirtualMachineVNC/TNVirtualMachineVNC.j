/*
 * TNViewHypervisorControl.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <AppKit/CPWebView.j>


/*! @defgroup  virtualmachinevnc Module VirtualMachineVNC 
    @desc This module allows to access to virtual machine displays
    using VNC.
*/


/*! @ingroup virtualmachinevnc
    @group TNArchipelTypeVirtualMachineControl
    namespave of vm control
*/
TNArchipelTypeVirtualMachineControl             = @"archipel:vm:control";

/*! @ingroup virtualmachinevnc
    @group TNArchipelTypeVirtualMachineControl
    get vnc display
*/
TNArchipelTypeVirtualMachineControlVNCDisplay   = @"vncdisplay";

/*! @ingroup virtualmachinevnc
    @group TNArchipelTypeVirtualMachineControl
    get virtual machine information
*/
TNArchipelTypeVirtualMachineControlInfo         = @"info";


/*! @ingroup virtualmachinevnc
    module that allow to access virtual machine console using VNC
*/
@implementation TNVirtualMachineVNC : TNModule
{
    @outlet CPTextField     fieldJID        @accessors;
    @outlet CPTextField     fieldName       @accessors;
    @outlet     CPWebView   vncWebView      @accessors;
    @outlet     CPView      maskingView     @accessors;

    CPString    _VMHost;
    CPString    _vncDisplay;
    CPString    _webServerPort;
}

/*! initialize some value at CIB awakening
*/
- (void)awakeFromCib
{
    [[self maskingView] setBackgroundColor:[CPColor whiteColor]];
    [[self maskingView] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self maskingView] setAlphaValue:0.9];

    _webServerPort   = [[CPBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"ArchipelServerSideWebServerPort"];
}

/*! TNModule implementation
*/
- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
}

/*! TNModule implementation
*/
- (void)willShow
{
    [super willShow];

    [[self maskingView] setFrame:[self bounds]];
    
    [[self fieldName] setStringValue:[[self entity] nickname]];
    [[self fieldJID] setStringValue:[[self entity] jid]];
    
    if ([[self entity] status] == TNStropheContactStatusOnline)
    {
        [[self maskingView] removeFromSuperview];
        [self getVirtualMachineVNCDisplay];
    }
    else
    {
        [[self maskingView] setFrame:[self bounds]];
        [self addSubview:[self maskingView]];
    }
}

/*! TNModule implementation
*/
- (void)willHide
{
    [super willHide];

    var bundle = [CPBundle bundleForClass:[self class]];

    [[self vncWebView] setMainFrameURL:[bundle pathForResource:@"empty.html"]];
    [[self maskingView] removeFromSuperview];
}

/*! TNModule implementation
*/
- (void)willUnload
{
    [super willUnload];

    [[self maskingView] removeFromSuperview];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self entity])
    {
       [[self fieldName] setStringValue:[[self entity] nickname]]
    }
}
/*! send stanza to get the current virtual machine VNC display
*/
- (void)getVirtualMachineVNCDisplay
{
    var vncStanza   = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineControl}];

    [vncStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineControlVNCDisplay}];

    [[self entity] sendStanza:vncStanza andRegisterSelector:@selector(_didReceiveVNCDisplay:) ofObject:self];
}

/*! message sent when VNC display info is received
    @param aStanza the response stanza
*/
- (void)_didReceiveVNCDisplay:(id)aStanza
{
    if ([aStanza getType] == @"success")
    {
        var displayNode = [aStanza firstChildWithName:@"vncdisplay"];
        _vncDisplay     = [displayNode valueForAttribute:@"port"];
        _VMHost         = [displayNode valueForAttribute:@"host"];

        var url     = @"http://" + _VMHost + @":" + _webServerPort + @"?port=" + _vncDisplay;

        [[self vncWebView] setMainFrameURL:url];
    }
}

@end



