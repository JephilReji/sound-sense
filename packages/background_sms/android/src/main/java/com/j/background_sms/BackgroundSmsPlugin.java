package com.j.background_sms;

import android.telephony.SmsManager;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class BackgroundSmsPlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "background_sms");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("sendSms") || call.method.equals("sendMessage")) {
      
      // FIX: The Dart package actually sends the phone number under the keyword "address"!
      String num = call.argument("address");
      if (num == null) num = call.argument("phoneNumber");
      if (num == null) num = call.argument("phone");
      
      String msg = call.argument("message");
      if (msg == null) msg = call.argument("msg");

      // Prevent the system crash if it's still null
      if (num == null || num.isEmpty()) {
          result.error("Failed", "Invalid destinationAddress (Number is null)", null);
          return;
      }

      try {
        SmsManager smsManager = SmsManager.getDefault();
        smsManager.sendTextMessage(num, null, msg, null, null);
        result.success("Sent");
      } catch (Exception ex) {
        result.error("Failed", "Sms Not Sent", ex.toString());
      }
    } else if (call.method.equals("isSupportCustomSim")) {
      result.success(false);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
    }
  }
}