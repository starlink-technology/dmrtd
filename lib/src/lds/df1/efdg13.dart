// Created by Crt Vavros, copyright © 2022 ZeroPass. All rights reserved.
// ignore_for_file: constant_identifier_names
import 'dart:convert';
import 'dart:typed_data';

import 'package:dmrtd/dmrtd.dart';
import 'package:dmrtd/extensions.dart';

class EfDG13 extends DataGroup {
  static const FID = 0x010D;
  static const SFI = 0x0D;
  static const TAG = DgTag(0x6D);
  static const TAG_LIST_TAG = 0x5c;

  // Store parsed optional details
  OtherPersonalInfo? _personalInfo;

  EfDG13.fromBytes(Uint8List data) : super.fromBytes(data);

  @override
  int get fid => FID;

  @override
  int get sfi => SFI;

  @override
  int get tag => TAG.value;

  OtherPersonalInfo? get personalInfo => _personalInfo;

  @override
  void parse(Uint8List content) {
    final tlv = TLV.fromBytes(content);
    if (tlv.tag != tag) {
      throw EfParseError(
          "Invalid DG13 tag=${tlv.tag.hex()}, expected tag=${TAG.value.hex()}");
    }

    final data = tlv.value;
    final tagListTag = TLV.decode(data);
    if (tagListTag.tag.value != TAG_LIST_TAG) {
      throw EfParseError(
          "Invalid tag list tag=${tagListTag.tag.value.hex()}, expected tag=5c");
    }

    var tagListLength = tlv.value.length;
    int tagListBytesRead = tagListTag.encodedLen;

    while (tagListBytesRead < tagListLength) {
      final uvtv = TLV.decode(data.sublist(tagListBytesRead));
      tagListBytesRead += uvtv.encodedLen;

      // Parse the data field
      _parseDataField(uvtv);
    }
  }

  void _parseDataField(DecodedTV tlv) {
    try {
      // The value should contain UTF-8 encoded text
      final utf8Text = utf8.decode(tlv.value);

      // Split by semicolons to get individual fields
      final fields = utf8Text.split(';');
      final Map<String, String> optionalDetails = {};
      for (final field in fields) {
        final trimmedField = field.trim();
        if (trimmedField.isEmpty) continue;

        // Split by '=' to get key-value pairs
        final parts = trimmedField.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value =
              parts.sublist(1).join('=').trim(); // In case value contains '='
          optionalDetails[key] = value;
        }
      }
      // Convert the optional details to PersonalInfo object
      _personalInfo = OtherPersonalInfo.fromMap(optionalDetails);
    } catch (e) {
      print('Error other parsing optional data field: $e');
    }
  }
}

class OtherPersonalInfo {
  final String fatherNationality;
  final String motherNationality;
  final String religion;
  final String ethnicity;
  final String civilStatusOffice;
  final String recordNumber;
  final String pageNumber;
  final String currentFamilyNumber;
  final String birthFamilyNumber;
  final String legalClause;
  final String fatherBirthPlace;
  final String motherBirthPlace;
  final String bloodType;

  OtherPersonalInfo({
    required this.fatherNationality,
    required this.motherNationality,
    required this.religion,
    required this.ethnicity,
    required this.civilStatusOffice,
    required this.recordNumber,
    required this.pageNumber,
    required this.currentFamilyNumber,
    required this.birthFamilyNumber,
    required this.legalClause,
    required this.fatherBirthPlace,
    required this.motherBirthPlace,
    required this.bloodType,
  });

  factory OtherPersonalInfo.fromMap(Map<String, String> map) {
    return OtherPersonalInfo(
      fatherNationality: map['جنسية الاب/ڕەگەزنامەی باوك'] ?? '',
      motherNationality: map['جنسية الام/ڕەگەزنامەی دایك'] ?? '',
      religion: map['الديانة/ئایین'] ?? '',
      ethnicity: map['القومية/ڕەگەزنامە'] ?? '',
      civilStatusOffice:
          map['دائرة الاحوال المدنية/فەرمانگەی کاروباری شارستانی'] ?? '',
      recordNumber: map['رقم السجل/ژمارەی پەرتووك'] ?? '',
      pageNumber: map['رقم الصحيفة/ژمارەی پەڕە'] ?? '',
      currentFamilyNumber:
          map['الرقم العائلي الحالي/ژمارەی خێزانی ھەنووکەیی'] ?? '',
      birthFamilyNumber:
          map['الرقم العائلي الولادي/ژمارەی خێزانی لەدایکبوو'] ?? '',
      legalClause: map['البند القانوني/بەندی یاسایی'] ?? '',
      fatherBirthPlace: map['محل ولادة الاب/شوێنی لەدایك بوونی باوك'] ?? '',
      motherBirthPlace: map['محل ولادة الام/شوێنی لەدایك بوونی دایك'] ?? '',
      bloodType: map['فئة الدم/گرووپی خوێن'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'جنسية الاب/ڕەگەزنامەی باوك': fatherNationality,
      'جنسية الام/ڕەگەزنامەی دایك': motherNationality,
      'الديانة/ئایین': religion,
      'القومية/ڕەگەزنامە': ethnicity,
      'دائرة الاحوال المدنية/فەرمانگەی کاروباری شارستانی': civilStatusOffice,
      'رقم السجل/ژمارەی پەرتووك': recordNumber,
      'رقم الصحيفة/ژمارەی پەڕە': pageNumber,
      'الرقم العائلي الحالي/ژمارەی خێزانی ھەنووکەیی': currentFamilyNumber,
      'الرقم العائلي الولادي/ژمارەی خێزانی لەدایکبوو': birthFamilyNumber,
      'البند القانوني/بەندی یاسایی': legalClause,
      'محل ولادة الاب/شوێنی لەدایك بوونی باوك': fatherBirthPlace,
      'محل ولادة الام/شوێنی لەدایك بوونی دایك': motherBirthPlace,
      'فئة الدم/گرووپی خوێن': bloodType,
    };
  }
}
