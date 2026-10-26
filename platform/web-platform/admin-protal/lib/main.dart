import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'core/bc_api_client.dart';
import 'features/auth/screens/admin_login_screen.dart';
import 'features/bc_eats/screens/admin_screen.dart';

/// Token handed over by the BC Ways & Eats app (see web/index.html).
@JS('bcTakeHandoffToken')
external JSString? _bcTakeHandoffToken();

/// Database roles allowed into the admin portal. The backend enforces the
/// same roles on every inventory request; this check only decides what to show.
const _portalRoles = {'admin', 'restaurant'};

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const BCAdminPortalApp()); }
class BCAdminPortalApp extends StatefulWidget { const BCAdminPortalApp({super.key}); @override State<BCAdminPortalApp> createState()=>_BCAdminPortalAppState(); }
class _BCAdminPortalAppState extends State<BCAdminPortalApp> {
 bool _checking=true, _authenticated=false;
 @override void initState(){super.initState();_restore();}
 Future<void> _restore() async {
   // A fresh handoff from the main app replaces any older saved session.
   final handoff = _bcTakeHandoffToken()?.toDart;
   if (handoff != null && handoff.isNotEmpty) {
     await BcApiClient.instance.setToken(handoff);
   } else {
     await BcApiClient.instance.restoreToken();
   }
   if (BcApiClient.instance.hasToken) {
     try { final r=await BcApiClient.instance.getJson('/api/users/me'); final u=(r['data'] as Map<String,dynamic>?)??{}; _authenticated=_portalRoles.contains(u['role']?.toString().toLowerCase()); }
     catch (_) { _authenticated=false; }
     if(!_authenticated) await BcApiClient.instance.clearToken();
   }
   if(mounted)setState(()=>_checking=false);
 }
 void _signedIn(){if(mounted)setState(()=>_authenticated=true);}
 @override Widget build(BuildContext context)=>MaterialApp(title:'BC Eats Admin Portal',debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFFF4C430))),home:_checking?const Scaffold(body:Center(child:CircularProgressIndicator())):_authenticated?AdminShellScreen(onSignOut:() async {await BcApiClient.instance.clearToken();if(mounted)setState(()=>_authenticated=false);}):AdminLoginScreen(onAuthenticated:_signedIn));
}
