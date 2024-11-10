import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool canVibrate = false;
late Directory docsDir;
late Directory tempDir;
const whatsappStickersPath = "Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Stickers";
late Dio dio;
final supabase = Supabase.instance.client;  
const mimeBotInviteUrl = "https://discord.com/oauth2/authorize?client_id=778018929670356993";