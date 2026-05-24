import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized service for In-App Update (Android) and In-App Review.
///
/// Usage:
/// ```dart
/// // On app startup (e.g., in NavigationPage.initState):
/// UpdateReviewService.instance.checkForUpdate();
/// UpdateReviewService.instance.maybePromptReview();
///
/// // On "Rate Us" button tap:
/// UpdateReviewService.instance.requestReview();
/// ```
class UpdateReviewService {
  UpdateReviewService._();
  static final UpdateReviewService instance = UpdateReviewService._();

  static const String _kAppOpenCountKey = 'app_open_count';
  static const int _kReviewPromptThreshold = 5;

  // Play Store URL as fallback for review
  static const String _kPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.legendarysoftware.redpdf.signpdf_scanpdf';

  final InAppReview _inAppReview = InAppReview.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // IN-APP UPDATE (Android only — Flexible mode)
  // ─────────────────────────────────────────────────────────────────────────

  /// Check for available updates and start a flexible update if one exists.
  ///
  /// On non-Android platforms this is a no-op.
  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        // Start flexible update (downloads in the background).
        await InAppUpdate.startFlexibleUpdate();

        // Once the download completes, prompt the user to restart.
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('UpdateReviewService — checkForUpdate error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IN-APP REVIEW
  // ─────────────────────────────────────────────────────────────────────────

  /// Request the native in-app review dialog.
  ///
  /// The OS may choose **not** to show the dialog (rate-limiting).
  /// If the in-app review flow is unavailable, falls back to opening the
  /// Play Store / App Store listing.
  Future<void> requestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        await _inAppReview.requestReview();
      } else {
        // Fallback: open the store listing externally.
        await _openStoreListing();
      }
    } catch (e) {
      debugPrint('UpdateReviewService — requestReview error: $e');
      // Last resort fallback.
      await _openStoreListing();
    }
  }

  /// Increment the app-open counter and prompt for a review once the
  /// threshold is reached. Calls [requestReview] at most **once** — the
  /// counter stops incrementing after the prompt has been triggered.
  Future<void> maybePromptReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_kAppOpenCountKey) ?? 0) + 1;

      if (count >= _kReviewPromptThreshold) {
        // Don't increment further — prompt has been triggered.
        await requestReview();
        // Reset or cap so we don't spam on every subsequent launch.
        // Setting to a negative sentinel so we never trigger again.
        await prefs.setInt(_kAppOpenCountKey, -1000);
      } else if (count > 0) {
        // Only increment if we haven't already triggered.
        await prefs.setInt(_kAppOpenCountKey, count);
      }
    } catch (e) {
      debugPrint('UpdateReviewService — maybePromptReview error: $e');
    }
  }

  /// Open the store listing externally (fallback).
  Future<void> _openStoreListing() async {
    try {
      // in_app_review also provides openStoreListing which handles both
      // Android and iOS.
      await _inAppReview.openStoreListing(
        appStoreId: '', // Not needed for Android
      );
    } catch (_) {
      // Final fallback: plain URL launch.
      final uri = Uri.parse(_kPlayStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
