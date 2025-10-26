import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';

void successScaffoldMsg(BuildContext context,String message, 
  {Color backgroundColor = AppTheme.primary, Color textColor = AppTheme.bg}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(
          message, 
          style: Theme.of(context).textTheme.titleLarge!.apply(color: textColor),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          ),
        duration: const Duration(seconds: 3),
        
      ),
    );
  }

  void errorScaffoldMsg(BuildContext context, String message,
  {Color backgroundColor = AppTheme.primary, Color textColor = AppTheme.bg}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.error,size: 40,color: Colors.red,),
            ),
            Text(message,
              overflow: TextOverflow.ellipsis,
              maxLines: 2, 
              style: Theme.of(context).textTheme.titleLarge!.apply(color: textColor,)),
          ],
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }