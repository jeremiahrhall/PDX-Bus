//
//  FindByLocationView.m
//  PDX Bus
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

#import "FindByLocationView.h"
#import "XMLAllStops.h"
#import "RootViewController.h"
#import "StopDistance.h"
#import "DepartureTimesView.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "CellLabel.h"
#import "NearestStopsMap.h"
#import "NearestRoutesView.h"
#import "debug.h"

#define kLocatingSection	0
#define kGoSection			1
#define kDistanceSection	2
#define kModeSection		3
#define kShowSection        4
#define kAutoSection        5
#define kNoteSection        6

#define kLocatingAccuracy	0
#define kLocatingStop		1

#define kShowArrivals		0
#define kShowMap			1
#define kShowRoute			2

#define kDistanceNextToMe	0
#define kDistanceHalfMile   1
#define kDistanceMile		2
#define kDistance3Miles		3

#define kSegRowWidth		320
#define kSegRowHeight		40
#define kUISegHeight		40
#define kUISegWidth			320

#define kAutoAsk            0
#define kAutoPrevious       1

#define kGoCellId			@"go"

#define kHelpText           @"Note: Using previous settings chosen in 'Locate nearby stops' main menu."

@implementation FindByLocationView

@synthesize cachedRoutes = _cachedRoutes;
@synthesize lastLocate   = _lastLocate;
@synthesize autoLaunch   = _autoLaunch;

// @synthesize progressText = _progressText;

- (void)dealloc {
	self.cachedRoutes = nil;
	self.lastLocate   = nil;

	[super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.title = @"Locate Stops";
		waitingForLocation = NO;
		maxRouteCount = 1;
		mode = TripModeAll;
        dist = kDistanceHalfMile;
        show = kShowArrivals;
        _firstDisplay = YES;
		
	 
		self.lastLocate = _userData.lastLocate;
        
        if (self.lastLocate != nil)
		{
			mode = ((NSNumber *)[self.lastLocate objectForKey:kLocateMode]).intValue;
			show = ((NSNumber *)[self.lastLocate objectForKey:kLocateShow]).intValue;
			dist = ((NSNumber *)[self.lastLocate objectForKey:kLocateDist]).intValue;
		}
		
        /*
		if (self.lastLocate != nil && !_autoLaunch)
		{
			mode = ((NSNumber *)[self.lastLocate objectForKey:kLocateMode]).intValue;	
			show = ((NSNumber *)[self.lastLocate objectForKey:kLocateShow]).intValue;	
			dist = ((NSNumber *)[self.lastLocate objectForKey:kLocateDist]).intValue;	
		}
        else if (_autoLaunch)
        {
            UserPrefs *prefs = [UserPrefs getSingleton];
            mode = prefs.autoLocateMode;
            show = kShowArrivals;
            dist = kDistanceHalfMile;
        }
        */
		
		[self reinit];
	}
	return self;
}

- (void)actionArgs:(NSDictionary *)args
{
    NSString *arg = [args objectForKey:@"distance"];
    
    if (arg !=nil)
    {
        NSDictionary *dmap = [[[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithInt:kDistanceNextToMe], @"closest",
                            [NSNumber numberWithInt:kDistanceNextToMe], @"Closest",
                            [NSNumber numberWithInt:kDistanceHalfMile], @"0.5",         
                            [NSNumber numberWithInt:kDistanceMile],     @"1",           
                            [NSNumber numberWithInt:kDistance3Miles],   @"3",           
                              nil] autorelease];
        
        NSNumber *num = [dmap objectForKey:arg];
        if (num)
        {
            dist = [num integerValue];
        }
    }
    
    arg = [args objectForKey:@"mode"];
    
    if (arg !=nil)
    {       
        NSDictionary *dmap = [[[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSNumber numberWithInt:TripModeBusOnly],    @"Bus",         
                               [NSNumber numberWithInt:TripModeBusOnly],    @"bus",
                               [NSNumber numberWithInt:TripModeBusOnly],    @"Busses",
                               [NSNumber numberWithInt:TripModeBusOnly],    @"busses",
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"Train",       
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"train",
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"Trains",
                               [NSNumber numberWithInt:TripModeTrainOnly],  @"trains",
                               [NSNumber numberWithInt:TripModeAll],        @"both",        
                               [NSNumber numberWithInt:TripModeAll],        @"Both",        
                               [NSNumber numberWithInt:TripModeAll],        @"BusAndTrain",
                               [NSNumber numberWithInt:TripModeAll],        @"busandtrain",
                               [NSNumber numberWithInt:TripModeAll],        @"BussesAndTrains",
                               [NSNumber numberWithInt:TripModeAll],        @"bussesandtrains",
                               
                               nil] autorelease];
        
        NSNumber *num = [dmap objectForKey:arg];
        if (num)
        {
            mode = [num integerValue];
        }
    }
    
    arg = [args objectForKey:@"show"];
    
    if (arg !=nil)
    {
        NSDictionary *dmap = [[[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSNumber numberWithInt:kShowArrivals],  @"Arrivals",
                               [NSNumber numberWithInt:kShowArrivals],  @"arrivals",
                               [NSNumber numberWithInt:kShowMap],       @"map",
                               [NSNumber numberWithInt:kShowMap],       @"Map",
                               [NSNumber numberWithInt:kShowRoute],     @"routes",
                               [NSNumber numberWithInt:kShowRoute],     @"Routes",
                               nil] autorelease];
        
        NSNumber *num = [dmap objectForKey:arg];
        if (num)
        {
            show = [num integerValue];
        }
    }
}

- (id) initAutoLaunch
{
    _autoLaunch = YES;
    
	return [self init];
}

- (void)startLocating
{
    switch (dist)
    {
        case kDistanceNextToMe:
            accuracy = kAccNextToMe;
            minDistance = kDistNextToMe;
            maxToFind = kMaxStops;
            break;	
        case kDistanceHalfMile:
            accuracy = kAccHalfMile;
            minDistance = kDistHalfMile;
            maxToFind = kMaxStops;
            break;
        case kDistanceMile:
            accuracy = kAccMile;
            minDistance = kDistMile;
            maxToFind = kMaxStops;
            break;
        case kDistance3Miles:
            accuracy = kAcc3Miles;
            minDistance = kDistMile * 3;
            maxToFind = kMaxStops;
            break;
    }
    
    [self.locationManager startUpdatingLocation];
    
    if (![self checkLocation])
    {
        waitingForLocation = true;
        [self reinit];
        [[(RootViewController *)[self.navigationController topViewController] table] reloadData];
        
        NSIndexPath *sel = self.table.indexPathForSelectedRow;
      
        if (sel)
        {
            [self.table deselectRowAtIndexPath:sel animated:NO];
        }
    }
    
}

#pragma mark TableViewWithToolbar methods

-(void)resetButton:(id)arg
{
    mode = TripModeAll;
    show = kShowArrivals;
    dist = kDistanceHalfMile;
    UserPrefs *prefs = [UserPrefs getSingleton];
    prefs.autoLocateShowOptions = YES;
    [self reloadData];
}

- (void)createToolbarItems
{
    UIBarButtonItem *resetButton = [[[UIBarButtonItem alloc]
                              initWithTitle:@"Reset Options" style:UIBarButtonItemStyleBordered
                              target:self action:@selector(resetButton:)] autorelease];
    
	NSArray *items = [NSArray arrayWithObjects: [self autoDoneButton], [CustomToolbar autoFlexSpace], resetButton, [CustomToolbar autoFlexSpace], nil];
	
    [self setToolbarItems:items animated:NO];
}

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark UI Helper functions

-(void)backButton:(id)sender
{
	[super backButton:sender];
}

- (int)sectionType:(int)section
{
	if (waitingForLocation || _autoLaunch)
	{
		DEBUG_LOG(@"Section %d returned %d\n", section, kLocatingSection);
		return kLocatingSection;
	}
	
	return section + 1;
}

- (void) reinit
{
	if (waitingForLocation || _autoLaunch)
	{
		sections		= 1;
	}
	else 
	{
		sections		= 6;
	}
}

- (void)searchAndDisplay
{
	[self.locationManager stopUpdatingLocation];
	[self reinit];
	
	switch (show)
	{
		case kShowMap:
		{
			NearestStopsMap *mapView = [[NearestStopsMap alloc] init];
			[mapView fetchNearestStopsInBackground:self.backgroundTask location:self.lastLocation maxToFind:maxToFind minDistance:minDistance mode:mode];
			
			if ([mapView supportsOverlays])
			{
				mapView.circle = [MKCircle circleWithCenterCoordinate:self.lastLocation.coordinate radius:minDistance];
			}
			[mapView release];
			break;
		}
		case kShowRoute:
		{
			NearestRoutesView *routesView = [[NearestRoutesView alloc] init];
			[routesView fetchNearestRoutesInBackground:self.backgroundTask location:self.lastLocation maxToFind:maxToFind minDistance:minDistance mode:mode];
			[routesView release];
			break;
		}
		case kShowArrivals:
		{
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			[departureViewController fetchTimesForNearestStopsInBackground:self.backgroundTask location:self.lastLocation maxToFind:maxToFind minDistance:minDistance mode:mode];
			[departureViewController release];
			break;
		}
	}
    
    if (_autoLaunch)
    {
        [self.backgroundTask setHelp:kHelpText];
    }
}



- (void)located
{
	[self searchAndDisplay];
}

#pragma mark Segment Controls

- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action
{
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
	
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.autoresizingMask =   UIViewAutoresizingFlexibleWidth;
	[parent addSubview:segmentedControl];
	[parent layoutSubviews];
	[segmentedControl autorelease];
	return segmentedControl;
}

- (void)modeSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	mode = seg.selectedSegmentIndex;
}

- (void)showSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	show = seg.selectedSegmentIndex;
}


- (void)distSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	dist = seg.selectedSegmentIndex;
}

- (void)autoSegmentChanged:(id)sender
{
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	
    UserPrefs *prefs = [UserPrefs getSingleton];
    
    switch (seg.selectedSegmentIndex)
    {
    case kAutoAsk:
            prefs.autoLocateShowOptions = YES;
            break;
    default:
    case kAutoPrevious:
            prefs.autoLocateShowOptions = NO;
            break;
    }
}



#pragma mark TableViewWithToolbar methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	switch ([self sectionType:section])
	{
		case kLocatingSection:
			return [NSString stringWithFormat:@"%@Acquiring location. Accuracy will improve momentarily; search will start when accuracy is sufficient or whenever you choose.",
                    self.autoLaunch ? kHelpText @"\n\n": @""];
		case kDistanceSection:
			return @"Search radius:";
		case kModeSection:
			return @"Mode of travel:";
		case kShowSection:
			return @"Show:";
        case kNoteSection:
            return @"Note: This page is always shown when 'Locate nearby stops' is selected from the main list.";
        case kAutoSection:
			return @"Locate toolbar button behavior:";
		case kGoSection:
			return nil; // [NSString stringWithFormat:@"Choosing 'Arrivals' will show a maximum of %d stops.", kMaxStops];
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
    switch ([self sectionType:section])
    {
        case kLocatingSection:
            return 2;
        case kNoteSection:
            return 0;
        default:
            return 1;
    }
    return 1;
}

#define kUIProgressBarWidth		240.0
#define kUIProgressBarHeight	10.0
#define kRowHeight				40.0

#define kRowWidth				300.0

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 0.0;

	switch ([self sectionType:indexPath.section])
	{
		case kLocatingSection:
			result = kLocatingRowHeight;
			break;
		case kDistanceSection:
		case kModeSection:
		case kShowSection:
        case kAutoSection:
            
			result = kSegRowHeight;
			break;
		case kGoSection:
			result = [self basicRowHeight];
			break;
	}
	return result;
}

- (UITableViewCell *)segCell:(NSString*)cellId items:(NSArray*)items action:(SEL)action
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
	
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
	CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
	segmentedControl.autoresizingMask =   UIViewAutoresizingFlexibleWidth;
	[cell.contentView addSubview:segmentedControl];
	[segmentedControl autorelease];
	
	[cell layoutSubviews];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.isAccessibilityElement = NO;
	cell.backgroundView = [self clearView];
	
	return cell;
	
}

- (UISegmentedControl *)getSeg:(UITableViewCell *)cell
{
	for (UIView *v in cell.contentView.subviews)
	{
		if ([v isKindOfClass:[UISegmentedControl class]])
		{
			return (UISegmentedControl *)v;
		}
	}
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"Location";
	
	DEBUG_LOG(@"Requesting cell for ip %d %d type %d\n", indexPath.section, indexPath.row, [self sectionType:indexPath.section]);
	
	switch ([self sectionType:indexPath.section])
	{
		case kDistanceSection:
		{
			static NSString *segmentId = @"dist";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId 
							   items:[NSArray arrayWithObjects:@"Closest", @"½ mile", @"1 mile", @"3 miles", nil]
							  action:@selector(distSegmentChanged:)];
			}	
			
			[self getSeg:cell].selectedSegmentIndex = dist;
			return cell;	
		}
		case kShowSection:
		{
			static NSString *segmentId = @"show";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId 
							   items:[NSArray arrayWithObjects:@"Arrivals", @"Map", @"Routes", nil]
							  action:@selector(showSegmentChanged:)];
			}	
			
			[self getSeg:cell].selectedSegmentIndex = show;
			return cell;	
		}
		case kModeSection:
		{
			static NSString *segmentId = @"mode";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId 
							   items:[NSArray arrayWithObjects:@"Bus only", @"Rail only", @"Bus or Rail", nil]
							  action:@selector(modeSegmentChanged:)];
			}	
			
			[self getSeg:cell].selectedSegmentIndex = mode;
			return cell;	
		}
        case kAutoSection:
		{
			static NSString *segmentId = @"auto";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:segmentId];
			if (cell == nil) {
				cell = [self segCell:segmentId
							   items:[NSArray arrayWithObjects:@"Show this page", @"Show results", nil]
							  action:@selector(autoSegmentChanged:)];
			}
			
            if ([UserPrefs getSingleton].autoLocateShowOptions)
            {
                [self getSeg:cell].selectedSegmentIndex = kAutoAsk;
            }
            else
            {
                [self getSeg:cell].selectedSegmentIndex = kAutoPrevious;

            }
			return cell;
		}
		case kGoSection:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGoCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGoCellId] autorelease];
			}
			cell.textLabel.text = @"Start locating";
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [self getBasicFont];
			
			[self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
			return cell;
		}
			
		case kLocatingSection:
		{
			switch (indexPath.row)
			{
				case kLocatingAccuracy:
				{
					static NSString *locSecid = @"LocatingSection";
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:locSecid];
					if (cell == nil) {
						cell = [self accuracyCellWithReuseIdentifier:locSecid];
					}
					
					UILabel* text = (UILabel *)[cell.contentView viewWithTag:[self LocationTextTag]];
					
					[self.progressInd startAnimating];
					
					if (self.lastLocation != nil)
					{
						text.text = [NSString stringWithFormat:@"Accuracy acquired:\n+/- %@", 
									 [self formatDistance:self.lastLocation.horizontalAccuracy]];
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
						[cell setAccessibilityHint:@"Double-tap for arrivals"];
					}
					else
					{
						text.text = @"Locating...";
						cell.accessoryType = UITableViewCellAccessoryNone;
						[cell setAccessibilityHint:nil];
					}
					[self updateAccessibility:cell indexPath:indexPath text:text.text alwaysSaySection:YES];
					return cell;
				}
				case kLocatingStop:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
					}
					cell.textLabel.text = @"Cancel";
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.imageView.image = [self getActionIcon:kIconCancel];
					cell.textLabel.font = [self getBasicFont];

					[self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
					return cell;
				}	
			}
		}
	}
		
	return nil;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch ([self sectionType:indexPath.section])
	{
		case kGoSection:
            [self startLocating];
			break;
		case kLocatingSection:
		{
			if (indexPath.row == kLocatingAccuracy && self.lastLocation!=nil)
			{
				[self searchAndDisplay];
			}
			else if(indexPath.row == kLocatingStop && !_autoLaunch)
			{
				waitingForLocation = NO;
				[self reinit];
				[tableView deselectRowAtIndexPath:indexPath animated:NO];
				[[(RootViewController *)[self.navigationController topViewController] table] reloadData];
			}
            else if (indexPath.row == kLocatingStop && _autoLaunch)
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
			break;
		}
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    if ([cell.reuseIdentifier isEqualToString:kGoCellId])
	{
		cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
	}
}


#pragma mark View methods

- (void)viewWillDisappear:(BOOL)animated
{
    if (!_autoLaunch)
    {
        self.lastLocate = [[[NSMutableDictionary alloc] init] autorelease];
	
        [self.lastLocate setObject:[NSNumber numberWithInt:mode] forKey:kLocateMode];
        [self.lastLocate setObject:[NSNumber numberWithInt:dist] forKey:kLocateDist];
        [self.lastLocate setObject:[NSNumber numberWithInt:show] forKey:kLocateShow];
	
        _userData.lastLocate = self.lastLocate;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_autoLaunch && !waitingForLocation && _firstDisplay)
    {
        _firstDisplay=NO;
        [self startLocating];
    }
}




- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark Background methods

- (void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    DEBUG_LOG(@"BackgroundTaskDone\n");
	waitingForLocation = false;
	if (cancelled && _autoLaunch)
    {
        [super BackgroundTaskDone:viewController cancelled:cancelled];
        if (self == self.navigationController.topViewController)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else
    {
        [self reinit];
        [super BackgroundTaskDone:viewController cancelled:cancelled];
        [self.table reloadData];
    }
}

@end

