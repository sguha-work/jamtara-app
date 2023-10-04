import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomCachedNetworkImage {
  static ClipRRect showNetworkImage(String imgUrl, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        imageUrl: imgUrl,
        height: size,
        width: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Padding(
          padding: EdgeInsets.all(5),
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) =>
            const Icon(Icons.account_circle_outlined, size: 60),
      ),
    );
  }
  static CachedNetworkImage showNetworkImageForReport(String imgUrl, double size) {
    return CachedNetworkImage(
      imageUrl: imgUrl,
      height: size,
      width: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Padding(
        padding: EdgeInsets.all(5),
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) =>
      const Icon(Icons.account_circle_outlined, size: 60),
    );
  }
}
