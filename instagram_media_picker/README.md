# instagram_media_picker

This package fetches a Instagram users media using the Instagram Basic Display API, then allows them to select photos.

The package handles Instagram Authentication then returns the users media including the captions, ids, media URLs, and timestamps.

If you want to just get the media and build your own picker, check out my other package instagram_media: https://pub.dev/packages/instagram_media

**Usage**
```
 final result = await Navigator.push(context, MaterialPageRoute(
    builder: (context) => InstagramMediaPicker(
        appID: '7080000000000', //IG app ID from FB Developer Account
        appSecret: '3752x0x0x0x0x0x0x0x0x0' //App Secret
    )
));

print(result[0]); //URLs
print(result[1]); //IDs
print(result[2]); //Captions
print(result[3]); //Timestamps
```