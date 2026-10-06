#import "POMediaTypes.h"
#import "POScreenshots.h"
#import "POStrings.h"

static BOOL POMatches(NSString *pattern, NSString *text) {
    static NSMutableDictionary<NSString *, NSRegularExpression *> *expressions;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ expressions = [NSMutableDictionary dictionary]; });
    NSRegularExpression *expression;
    @synchronized (expressions) {
        expression = expressions[pattern];
        if (!expression) {
            expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
            expressions[pattern] = expression;
        }
    }
    return [expression firstMatchInString:text options:0 range:NSMakeRange(0, text.length)] != nil;
}

static BOOL POInFolder(POPhotoItem *item, NSString *name) {
    for (NSString *folder in [item.currentFolder componentsSeparatedByString:@"/"]) {
        if ([folder rangeOfString:name options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    }
    return NO;
}

NSString *POTypeFolder(POPhotoItem *item) {
    NSString *base = item.url.lastPathComponent.stringByDeletingPathExtension.precomposedStringWithCanonicalMapping;
    NSString *extension = item.url.pathExtension.lowercaseString;
    if (POIsScreenshot(item)) return POL(@"Скриншоты");
    if (item.isVideo && POMatches(@"^(rpreplay|screenrecording|screen recording|screen_recording|screenrecorder|запись экрана|record_screen)", base)) {
        return POL(@"Записи экрана");
    }
    if (POMatches(@"^(img|vid|aud|ptt|stk)-\\d{8}-wa\\d+", base) || POInFolder(item, @"whatsapp")) return @"WhatsApp";
    if (POMatches(@"^(photo|video|file)_\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}|^telegram-(cloud|peer)-", base) || POInFolder(item, @"telegram")) return @"Telegram";
    if (POMatches(@"^viber[_ ]", base) || POInFolder(item, @"viber")) return @"Viber";
    if (POInFolder(item, @"instagram")) return @"Instagram";
    if (item.isVideo) return POL(@"Видео");
    if ([extension isEqualToString:@"gif"]) return POL(@"Анимации");
    static NSSet<NSString *> *raw;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        raw = [NSSet setWithArray:@[@"dng", @"cr2", @"cr3", @"crw", @"nef", @"nrw", @"arw", @"srf", @"sr2", @"raf", @"orf", @"rw2", @"pef",
                                    @"srw", @"x3f", @"3fr", @"erf", @"kdc", @"rwl", @"iiq"]];
    });
    if ([raw containsObject:extension]) return @"RAW";
    if (POMatches(@"^pano[_-]", base)) return POL(@"Панорамы");
    if (item.pixelWidth > 0 && item.pixelHeight > 0
        && (double)MAX(item.pixelWidth, item.pixelHeight) / MIN(item.pixelWidth, item.pixelHeight) >= 2.5) return POL(@"Панорамы");
    return POL(@"Фото");
}

NSString *POFormatFolder(POPhotoItem *item) {
    NSString *extension = item.url.pathExtension.uppercaseString;
    if ([@[@"JPG", @"JPEG", @"JPE"] containsObject:extension]) return @"JPEG";
    if ([@[@"TIF", @"TIFF"] containsObject:extension]) return @"TIFF";
    if ([@[@"HEIC", @"HEIF"] containsObject:extension]) return @"HEIC";
    return extension.length ? extension : POL(@"Без расширения");
}
