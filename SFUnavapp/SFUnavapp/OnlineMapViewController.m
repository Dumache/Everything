//
//  OnlineMapViewController.m
//  SFUnavapp
//  Team NoMacs
//
//  Created by James Leong on 2015-03-15.
//  Copyright (c) 2015 Team NoMacs. All rights reserved.
//

#import "OnlineMapViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface OnlineMapViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clrbtn;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic) GMSMapView *sfumapView;

@property (strong, nonatomic) NSMutableArray* allTableData;
@property (strong, nonatomic) NSMutableArray* filteredTableData;
@property (nonatomic, assign) bool isFiltered;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLPlacemark *placemark;

@end


@implementation OnlineMapViewController {
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.topItem.title = @"";
    //// this block enables iOS 8 to use location services, will  not buliding in xcode,
    //comment the block out to test proj in xcode 5
    self.locationManager = [[CLLocationManager alloc] init];
    self.geocoder = [[CLGeocoder alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    //
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:49.278094
                                                            longitude:-122.919883
                                                                 zoom:15];

    self.sfumapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    
    [self.view insertSubview:_sfumapView atIndex:0];
    //code to autoresize the map in different orientations
    _sfumapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _sfumapView.myLocationEnabled = YES;
    //Controls the type of map tiles that should be displayed.
    _sfumapView.mapType = kGMSTypeNormal;
    //Shows the compass button on the map
    //header bar coers the compass for some reason
    _sfumapView.settings.compassButton = YES;
    //Shows the my location button on the map
    _sfumapView.settings.myLocationButton = YES;
    //Sets the view controller to be the GMSMapView delegate
    _sfumapView.delegate = self;

    
    [self.view insertSubview:_searchBar aboveSubview:_sfumapView];

    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(49.278094, -122.919883);
    marker.title = @"SFU";
    marker.snippet = @"Burnaby";
    marker.map = _sfumapView;
    
    _testTable.hidden = YES;
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"SFUlatlong" ofType:@"plist"];
    _allTableData = [NSMutableArray arrayWithContentsOfFile:path];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.title=@"Google Maps";
}
// Location Manager Delegate Methods, comment out to test in xcodd 5.1.1/ iOS 7
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //NSLog(@"%@", [locations lastObject]);
}
- (IBAction)clearMark:(id)sender {
    [_sfumapView clear];
}


- (BOOL)searchBarShouldBeginEditing:(UISearchBar*)searchBar {
    self.testTable.hidden = NO;
    return YES;
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.testTable.hidden =YES;
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    
    [searchBar setShowsCancelButton:YES animated:YES];
}


-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    //This'll Hide The cancelButton with Animation
    [searchBar setShowsCancelButton:NO animated:YES];
    //remaining Code'll go here
    self.testTable.hidden =YES;
    [searchBar resignFirstResponder];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// maybe not allow users to make markers by touch to avoid clustering
- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    GMSMarker *usertapMarker = [[GMSMarker alloc] init];
    usertapMarker.appearAnimation = kGMSMarkerAnimationPop;
    usertapMarker.position = coordinate;
    
    // make location object
    CLLocation *taploc = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    //NSLog(@"Resolving the Address");
    //initialize geocoder with google's data for addresses
    [_geocoder reverseGeocodeLocation:taploc completionHandler:^(NSArray *placemarks, NSError *error) {
        //NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            _placemark = [placemarks lastObject];
            usertapMarker.title = [NSString stringWithFormat:@"%@ %@",
                                   _placemark.subThoroughfare, _placemark.thoroughfare];
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
    //usertapMarker.title = [NSString stringWithFormat:@"%f, %f", coordinate.latitude, coordinate.longitude];
    usertapMarker.map = _sfumapView;
}


//table and search view methods here

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int rowCount;
    if(self.isFiltered)
        rowCount = (int) _filteredTableData.count;
    else
        rowCount = (int)_allTableData.count;
    
    return rowCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    NSDictionary *singleD;
    if(_isFiltered)
        singleD = [_filteredTableData objectAtIndex:indexPath.row];
    else
        singleD = [_allTableData objectAtIndex:indexPath.row];
    
    cell.textLabel.text = singleD[@"Building"];
    
    return cell;
}

#pragma mark - Table view delegate

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    if(text.length == 0)
    {
        _isFiltered = FALSE;
    }
    else
    {
        _isFiltered = true;
        _filteredTableData = [[NSMutableArray alloc] init];
        
        for (NSDictionary* singleD in _allTableData)
        {
            NSRange nameRange = [singleD[@"Building"] rangeOfString:text options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound)
            {
                [_filteredTableData addObject:singleD
                 ];
            }
        }
    }
    
    [self.testTable reloadData];
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self showDetailsForIndexPath:indexPath];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    [self showDetailsForIndexPath:indexPath];
}

// the method to handle selection in the filterable table
-(void) showDetailsForIndexPath:(NSIndexPath*)indexPath
{
    [self.searchBar resignFirstResponder];
    NSDictionary* singleD;
    if(_isFiltered)
        singleD = [_filteredTableData objectAtIndex:indexPath.row];
    else
        singleD = [_allTableData objectAtIndex:indexPath.row];
    
    // convert the latitude longitude strings to doubles
    
    //NSLog(@"%@ %@ %@", singleD[@"Building"],singleD[@"Latitude"], singleD[@"Longitude"]);
    
    NSString *trimlat = [singleD[@"Latitude"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *trimlon = [singleD[@"Longitude"]  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //Convert to double
    double latdouble = [trimlat doubleValue];
    double londouble = [trimlon doubleValue];
    
    GMSMarker *selectMarker = [[GMSMarker alloc] init];
    selectMarker.appearAnimation = kGMSMarkerAnimationPop;
    selectMarker.position = CLLocationCoordinate2DMake((latdouble), (londouble));
    
    selectMarker.title = [NSString stringWithFormat:@"%@", singleD[@"Building"]];
    selectMarker.map = _sfumapView;
    NSLog(@"dropped marker at %f, %f", latdouble, londouble);
    self.testTable.hidden = YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
