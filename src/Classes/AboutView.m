//
//  About.m
//  TriMetTimes
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "AboutView.h"
#include "CellLabel.h"
#include "WebViewController.h"
#include "TriMetXML.h"
#import "WhatsNewView.h"
#import "SupportView.h"
#import "debug.h"


#define kSectionHelp			0
#define kSectionWeb				1
#define kSectionLegal			2
#define kSectionAbout			3
#define kSections				4

#define kRowSite				0
#define kLinkTracker			1
#define kLinkStopIDs			2
#define kRowPortlandTransport   3
#define kRowTriMet				4

#define kLinkRows				5

#define kLegalRows				15
#define kRowCivicApps			0
#define kRowMainIcon			1
#define kRowIcons				2
#define kRowTWG					3
#define kRowSettings            4
#define KRowOtherIcons			5
#define kRowOxygen				6
#define kRowGeoNames			7
#define kRowPolygons			8
#define kRowRefresh             9
#define kRowZXing               10
#define kRowGentleface          11
#define kRowMyell0w             12
#define kRowChrome              13
#define kRowSrc					14
			
#define kSectionHelpRows		3
#define kSectionHelpRowHelp		0
#define kSectionHelpRowNew		1
#define kSectionHelpHowToRide   2


@implementation AboutView

@synthesize hideButton = _hideButton;

- (void)dealloc {
	[aboutText release];
	[helpText release];
	[super dealloc];
}

#pragma mark Helper functions

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Table view methods


- (id)init {
	if ((self = [super init]))
	{
		self.title = @"About";
		aboutText = [[NSString stringWithFormat:@"Version %@\n\n"
		"Route and arrival data provided by permission of TriMet.\n\n"
		"This app was developed as a volunteer effort to provide a service for TriMet riders. The developer has no affiliation with TriMet, AT&T or Apple.\n\n"
		"Lots of thanks...\n\n"
		"...to http://www.portlandtransport.com for help and advice;\n\n"
		"...to Scott, Tim and Mike for beta testing and suggestions;\n\n"
		"...to Scott (again) for lending me his brand new iPad;\n\n"
		"...to Rob Alan for the stylish icon; and\n\n"
		"...to CivicApps.org for Awarding PDX Bus the \"Most Appealing\" and \"Best in Show\" awards in July 2010.\n\n"
		"Special thanks to Ken for putting up with all this.\n\n"
		"\nCopyright (c) 2008-2013\nAndrew Wallace\n(See legal section above for other copyright owners and attrbutions).", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] retain];
		
		helpText = @"PDX Bus uses real-time tracking information from TriMet to display bus, MAX, WES and streetcar times for the Portland, Oregon, metro area.\n\n"
			"Every TriMet bus stop and rail station has its own unique Stop ID number, up to five digits.\n\n"
			"Enter the Stop ID to get the arrivals for that stop. You may also scan a QR code (found at some stops), or browse & search the routes to find a stop, or use a "
			"map of the rail system. The Trip Planner feature uses scheduled times to arrange a journey with several transfers.\n\n"
			"See below for other tips and links, touch here to start using PDX Bus.";
        
        _hideButton = NO;
    }
	return self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	
    if (!_hideButton)
    {
        UIBarButtonItem *info = [[[UIBarButtonItem alloc]
                                  initWithTitle:@"Help"
                                  style:UIBarButtonItemStyleBordered
                                  target:self action:@selector(infoAction:)] autorelease];
        
        
        self.navigationItem.rightBarButtonItem = info;
	}
}

- (void)infoAction:(id)sender
{
	SupportView *infoView = [[SupportView alloc] init];
	
	// Push the detail view controller
    
    infoView.hideButton = YES;

	[[self navigationController] pushViewController:infoView animated:YES];
	[infoView release];
	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kSectionAbout:
			return @"PDX Bus - Portland Transit Times";
		case kSectionWeb:
			return @"Links";
		case kSectionLegal:
			return @"Attributions and Legal";
		case kSectionHelp:
			return @"Welcome to PDX Bus!";
			
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kSectionAbout:
			return 1;
		case kSectionHelp:
			return kSectionHelpRows;
		case kSectionWeb:
			return kLinkRows;
		case kSectionLegal:
			return kLegalRows;
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
		case kSectionAbout:
		case kSectionHelp:
		{
			if (indexPath.row == kSectionHelpRowHelp)
			{
				static NSString *aboutId = @"about";
				CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:aboutId];
				if (cell == nil) {
					cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:aboutId] autorelease];
					cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
				}
				
				cell.view.font =  [self getParagraphFont];
				cell.view.text = (indexPath.section == kSectionAbout) ? aboutText : helpText;
				DEBUG_LOG(@"help width:  %f\n", cell.view.bounds.size.width);
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				[self updateAccessibility:cell indexPath:indexPath text:((indexPath.section == kSectionAbout) ? aboutText : helpText) alwaysSaySection:YES];
				// cell.backgroundView = [self clearView];
				return cell;
			}
			else {
				static NSString *newId = @"newid";
				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:newId];
				if (cell == nil) {
					
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newId] autorelease];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					/*
					 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
					 */
					
					cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
                
                if (indexPath.row == kSectionHelpHowToRide)
                {
                    cell.textLabel.text = @"How to ride";
                    cell.imageView.image = [self getActionIcon:kIconAbout];
                }
                else 
                {
                    cell.textLabel.text = @"What's new?";
                    cell.imageView.image = [self getActionIcon:@"Icon-Small.png"];
                }
				return cell;
			}

			break;
		}
		case kSectionWeb:
		{
			static NSString *linkId = @"pdxbuslink";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:linkId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:linkId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
				
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.textColor = [UIColor blueColor];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			
			switch (indexPath.row)
			{
			case kLinkTracker:	
				cell.textLabel.text = @"About TriMet's Transit Tracker";
				cell.imageView.image = [self getActionIcon:kIconLink];
				break;
			case kLinkStopIDs:
				cell.textLabel.text = @"About Stop IDs";
				cell.imageView.image = [self getActionIcon:kIconLink];
				break;
			case kRowSite:
				cell.textLabel.text = @"PDX Bus web site & Support";
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
			case kRowTriMet:
				cell.textLabel.text = @"TriMet.org";
				cell.imageView.image = [self getActionIcon:kIconTriMetLink];
				break;
            case kRowPortlandTransport:
				cell.textLabel.text = @"PortlandTransport.com";
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
			}
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"Link to %@", cell.textLabel.text]];
			return cell;
			break;
		}
		case kSectionLegal:
		{
			static NSString *linkId = @"pdxbuslink";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:linkId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:linkId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
				
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.textColor = [UIColor blueColor];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			
			switch (indexPath.row)
			{
				case kRowOxygen:
					cell.textLabel.text = @"Some icons from Oxygen-Icons.org";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
				case kRowIcons:
					cell.textLabel.text = @"Icons by Joseph Wain / glyphish.com";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
				case kRowTWG:
					cell.textLabel.text = @"Some toolbar icons by TWG";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
                case kRowChrome:
					cell.textLabel.text = @"Open in Chrome from Google";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
                case kRowSettings:
					cell.textLabel.text = @"Uses code from www.inappsettingskit.com";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
				case kRowGeoNames:
					cell.textLabel.text = @"Location names from GeoNames.org";
					cell.imageView.image = [self getActionIcon:kIconEarthMap];
					break;	
				case kRowPolygons:
					cell.textLabel.text = @"Polygon code (c) 1970-2003, Wm. Randolph Franklin";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
				case kRowMainIcon:
					cell.textLabel.text = @"App icon by Rob Alan";
					cell.imageView.image = [self getActionIcon:@"Icon-Small.png"];
					break;
				case kRowCivicApps:
					cell.textLabel.text = @"Thanks for the Civic App award!";
					cell.imageView.image = [self getActionIcon:kIconAward];
					break;
				case kRowSrc:
					cell.textLabel.text = @"Source Code";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
				case KRowOtherIcons:
					cell.textLabel.text = @"Some icons by Aha-Soft";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
                case kRowRefresh:
					cell.textLabel.text = @"Pull to Refresh (c) 2010 Leah Culver";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
                case kRowZXing:
					cell.textLabel.text = @"QR Scanning from ZXing library";
					cell.imageView.image = [self getActionIcon:kIconSrc];
					break;
                case kRowGentleface:
					cell.textLabel.text = @"Some icons by Gentleface";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;
                case kRowMyell0w:
					cell.textLabel.text = @"Some icons from myell0w";
					cell.imageView.image = [self getActionIcon:kIconBrush];
					break;

					
			}
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"Link to %@", cell.textLabel.text]];
			return cell;
			break;
		}
		default:
			break;
	}
	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case kSectionAbout:
			return [self getTextHeight:aboutText font:[self getParagraphFont]];
			break;
		case kSectionHelp:
			if (indexPath.row == kSectionHelpRowHelp)
			{
				return [self getTextHeight:helpText font:[self getParagraphFont]];
			}
			break;
		case kSectionWeb:
		case kSectionLegal:
			return [self basicRowHeight];
		default:
			break;
	}
	return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionWeb:
		{
			WebViewController *webPage = [[WebViewController alloc] init];
		
			switch (indexPath.row)
			{
				case kLinkTracker:	
					[webPage setURLmobile:@"http://trimet.org/transittracker/about.htm" full:nil title:@"Transit Tracker"]; 
					break;
				case kLinkStopIDs:
					[webPage setURLmobile:@"http://trimet.org/transittracker/stopidnumbers.htm" full:nil title:@"Stop IDs"];
					break;
				case kRowSite:	
					[webPage setURLmobile:@"http:/pdxbus.teleportaloo.org" full:nil title:@"pdxbus.teleportaloo.org"]; 
					break;
				case kRowTriMet:
					[webPage setURLmobile:@"http://m.trimet.org/" full:@"http://www.trimet.org/" title:@"TriMet.org"];
					break;
				case kRowPortlandTransport:
					[webPage setURLmobile:@"http://portlandtransport.com" full:nil title:@"portlandtransport.com"];
					break;
			}
	
			[webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
			[webPage release];
			break;
		}
		case kSectionLegal:
		{
			WebViewController *webPage = [[WebViewController alloc] init];
			
			switch (indexPath.row)
			{
				case kRowOxygen:
					[webPage setURLmobile:@"http://www.oxygen-icons.org" full:nil title:@"Oxygen Icons"];
					break;
				case kRowIcons:
					[webPage setURLmobile:@"http://glyphish.com/" full:nil title:@"glyphish.com"];
					break;
				case kRowGeoNames:
					[webPage setURLmobile:@"http://geonames.org/" full:nil title:@"GeoNames.org"];
					break;
				case kRowPolygons:
					[webPage setURLmobile:@"http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html" full:nil title:@"pnpoly"];
					break;
				case kRowMainIcon:
					[webPage setURLmobile:@"http://www.robalan.com" full:nil title:@"Rob Alan"];
					break;
				case kRowCivicApps:
					[webPage setURLmobile:@"http://civicapps.org/news/announcing-best-apps-winners-and-runners" full:nil title:@"CivicApps.org"];
					break;
				case kRowSrc:
					[webPage setURLmobile:@"https://github.com/teleportaloo/PDX-Bus" full:nil title:@"Source Code"];
					break;
				case KRowOtherIcons:
					[webPage setURLmobile:@"http://www.small-icons.com/icons.htm" full:nil title:@"Aha-Soft"];
					break;
				case kRowTWG:
					[webPage setURLmobile:@"http://blog.twg.ca/2009/09/free-iphone-toolbar-icons/" full:nil title:@"TWG"];
					break;
                case kRowSettings:
					[webPage setURLmobile:@"http://www.inappsettingskit.com/" full:nil title:@"www.inappsettingskit.com"];
					break;
                case kRowRefresh:
					[webPage setURLmobile:@"https://github.com/leah/PullToRefresh" full:nil title:@"Pull to Refresh"];
					break;
                case kRowZXing:
					[webPage setURLmobile:@"http://code.google.com/p/zxing/" full:nil title:@"ZXing"];
					break;
                case kRowMyell0w:
					[webPage setURLmobile:@"https://github.com/myell0w/MTLocation" full:nil title:@"myell0w"];
					break;
                case kRowChrome:
					[webPage setURLmobile:@"https://github.com/GoogleChrome/OpenInChrome" full:nil title:@"Open in Chrome"];
					break;
                    
                    
			}
			
			[webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
			[webPage release];
			break;
		}
		case kSectionHelp:
			if (indexPath.row == kSectionHelpRowHelp)
			{
				[[self navigationController] popViewControllerAnimated:YES];
			}
			else if (indexPath.row == kSectionHelpHowToRide)
            {
                WebViewController *webPage = [[WebViewController alloc] init];
                [webPage setURLmobile:@"http://trimet.org/howtoride/index.htm" full:nil title:@"How to ride"]; 
                [webPage displayPage:[self navigationController] animated:YES tableToDeselect:self.table];
                [webPage release];
            }
            else
			{
				WhatsNewView *whatsNew = [[WhatsNewView alloc] init];
				[[self navigationController] pushViewController:whatsNew animated:YES];
				[whatsNew release];
			}
			break;
	}
}

@end

