import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The class will display an overlay to enlarge the given image
/// The image is received by the [imageUrl] given, which will then
/// be cached. An [imageDesc] can be given to display text over the 
/// image to give more information to the user
class FocusImage extends StatefulWidget {
  final String imageUrl;
  final String? imageDesc;
  const FocusImage(
    this.imageUrl,
    {this.imageDesc,
    super.key}
  );

  @override
  State<FocusImage> createState() => _FocusImageState();
}

class _FocusImageState extends State<FocusImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(.8),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context);
        },
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  flex: 1,
                  child: Text(
                    "Tap to dismiss",
                    style: TextStyle(
                      fontSize: 15
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          widget.imageDesc ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        progressIndicatorBuilder: (context, url, progress) => 
                          Center(
                            child: CircularProgressIndicator(value: progress.progress),
                          ),
                      )
                    ],
                  ))
              ],
            ),
          ),
        ),
      ),
    );
  } 
}