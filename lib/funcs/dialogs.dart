import 'package:flutter/material.dart';

void showErr(BuildContext context, String title, String content){
  showDialog(
    context: context, 
    builder: (context)=>AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        FilledButton(
          onPressed: (){
            Navigator.pop(context);
          }, 
          child: const Text('好的')
        )
      ],
    )
  );
}