#import <Foundation/Foundation.h>
#import "POPhotoItem.h"

NS_ASSUME_NONNULL_BEGIN

/// The folder a file goes to when the library is organized by type — told by what the file itself says (its name,
/// folder, format and proportions), the way Photos lists its media types: Screenshots, Screen Recordings, WhatsApp,
/// Telegram, Viber, Instagram, Videos, Animations, RAW, Panoramas, Photos.
FOUNDATION_EXPORT NSString *POTypeFolder(POPhotoItem *item);

/// The folder a file goes to when the library is organized by format: JPEG, HEIC, PNG, MOV…
FOUNDATION_EXPORT NSString *POFormatFolder(POPhotoItem *item);

NS_ASSUME_NONNULL_END
