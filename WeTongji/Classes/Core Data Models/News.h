//
//  News.h
//  WeTongji
//
//  Created by 紫川 王 on 12-5-29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface News : NSManagedObject

@property (nonatomic, retain) NSString * avatar_link;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * create_at;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSString * news_id;
@property (nonatomic, retain) NSNumber * read_count;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * update_date;
@property (nonatomic, retain) NSString * image_link;

@end
