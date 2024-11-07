import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';


/// Class that caches the given image from the URL using CachedNetworkImage
/// If no image is given or found, it will display the first two initals of the
/// name given
/// The initials determin what color the background will be
class CachedProfilePicture extends StatelessWidget {
  const CachedProfilePicture({
    super.key,
    required this.name,
    this.imageUrl,
    required this.radius,
    required this.fontSize,
  });

  final double radius;
  final String? imageUrl;
  final String name;
  final double fontSize;

  Color _getColorFromLetter(String c){
    RegExp greenMatch = RegExp(r'[A-C]|[M-O]');
    RegExp blueMatch = RegExp(r'[D-F]|[X-Z]');
    RegExp orangeMatch = RegExp(r'[G-I]|[U-W]');
    RegExp yellowMatch = RegExp(r'[J-L]|[Q-T]');
    RegExp pinkMatch = RegExp(r'[P]');
    if(greenMatch.hasMatch(c)){
      return Colors.green;
    }
    if(blueMatch.hasMatch(c)){
      return Colors.blue;
    }
    if(orangeMatch.hasMatch(c)){
      return Colors.orange;
    }
    if(yellowMatch.hasMatch(c)){
      return Colors.yellow;
    }
    if(pinkMatch.hasMatch(c)){
      return Colors.pink;
    }
    return Colors.white;
  }
  @override
  Widget build(BuildContext context) {
    String profileInit;

    // Get the initals of the user's name
    profileInit = name
    .split(" ")
    .map((word) {
      if(word.isNotEmpty) {
        return word[0];
      }
      return ""; 
    })
    .join("").toUpperCase();

    // Get only the first 2
    profileInit = profileInit.substring(0, profileInit.length >= 2 ? 2 : 1);
    Color profileColor = _getColorFromLetter(profileInit[0]);
    return CircleAvatar(
      radius: radius,
      backgroundColor: profileColor,
      child: imageUrl != null 
      ? CachedNetworkImage(
          memCacheHeight: 100,
          memCacheWidth: 100,
          imageUrl: imageUrl!,
          progressIndicatorBuilder: (context, url, progress) =>
            CircularProgressIndicator(value: progress.progress),
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider, fit: BoxFit.cover
              ),
            ),
          ),
          errorWidget: (context, url, error) => 
            Text(
              profileInit,
              style: TextStyle(
                fontSize: fontSize
              )
            ),
        )
      : Text(
          profileInit,
          style: TextStyle(
            fontSize: fontSize
          )
        )
    );
  }
}