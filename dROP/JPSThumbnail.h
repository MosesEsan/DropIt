//
//  JPSThumbnail.h
//  JPSThumbnailAnnotation
//  Created by Giovanni Arixi
//  Original Created by Jean-Pierre Simard on 4/22/13.
//
//  Copyright (c) 2013 JP Simard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

typedef void (^ActionBlock)();

@interface JPSThumbnail : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *imgUrl;
@property (nonatomic, strong) PFFile *file;

@property (nonatomic, strong) NSDictionary *postObject;
@property (nonatomic) NSInteger index;

@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) ActionBlock disclosureBlock;

@end
