import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoveGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'MoveGo'),
    );
  }
}

class CoreLogic{
  static final CoreLogic _instance = CoreLogic._internal();
  factory CoreLogic() => _instance;
  CoreLogic._internal();
  final plat= MethodChannel("wasd");
  int steps=0;
  int allsteps=0;
  String lastDate=DateTime.now().toString().split(' ')[0];
  List<double> week = List.filled(7, 0.0);
  List<double> month = List.filled(12, 0.0);
  Function? _onUpdate;
  Future<void> save() async{
    String js = jsonEncode({
      "steps": steps,
      "allsteps": allsteps,
      "date": lastDate,
      "week": week,
      "month": month,
    });
    await plat.invokeMethod("save",{"json":js});
  }
  Future<Map<String,dynamic>> load() async{
    String? js = await plat.invokeMethod("load","");
    if(js==null || js.isEmpty) return{};
    return jsonDecode(js);
  }
  void _checkDate(){
    String todayStr = DateTime.now().toString().split(' ')[0];
    if(lastDate == todayStr) return;
    DateTime last = DateTime.parse(lastDate);
    DateTime today = DateTime.parse(todayStr);
    int dayOff = today.difference(last).inDays;
    for(int i = 0;i<dayOff;i++){
      week.removeAt(0);
      week.add(0);
    }
    int monOff = (today.year - last.year) * 12 + (today.month - last.month);
    for(int i = 0;i<monOff;i++){
      month.removeAt(0);
      month.add(0);
    }
    steps =0;
    lastDate = todayStr;
    save();
  }
  void printAll(){
    print(steps);
    print(allsteps);
    print(lastDate);
    print(week);
    print(month);
  }
  void init(Function onUpdate){
    _onUpdate = onUpdate;
    load().then((data){
      if(data.containsKey("steps")){
        steps=data["steps"];
        allsteps=data["allsteps"];
        lastDate=data["date"];
        if(data.containsKey("week")) week = List<double>.from(data["week"]);
        if(data.containsKey("month")) month = List<double>.from(data["month"]);
        _checkDate();
        printAll();
        _onUpdate?.call();
      }
    });
    plat.setMethodCallHandler((handler) async{
      if(handler.method == "onsss"){
        _checkDate();
        steps++;
        allsteps++;
        week.last++;
        month.last++;
        save();
        printAll();
        _onUpdate?.call();
      }
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final core = CoreLogic();
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    core.init((){setState(() {});});
  }

  @override
  Widget build(BuildContext context) {
    double program = core.steps / 10000;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(children: [Column(mainAxisAlignment: MainAxisAlignment.center,children: [
        SizedBox(height: 20,),
        Stack(alignment: Alignment.center,children: [
          SizedBox(height: 200,width: 200,child: CircularProgressIndicator(
            value: program>1?1:program,
            strokeWidth: 15,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.grey,
          ),),
          Column(mainAxisAlignment: MainAxisAlignment.center,children: [
            Text("${core.steps}",style: TextStyle(fontSize: 48,fontWeight: FontWeight.bold,color: Colors.black),),
            Text("步 數",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold,color: Colors.black),),
            Text("目標：10,000",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.black),),
          ],)
        ],),
        SizedBox(height: 20,),
        Row(mainAxisAlignment: MainAxisAlignment.center,children: [
          Card(child: Padding(padding: EdgeInsets.all(20),child:Column(children: [
            Text("今日行走距離",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.black),),
            SizedBox(height: 10,),
            Text(core.steps/500 > 1 ? core.steps/500 > 10 ? core.steps/500 > 100 ? "${(core.steps/500).toInt()} km" :"${(core.steps/500).toStringAsFixed(1)} km" :"${(core.steps/500).toStringAsFixed(2)} km": "${(core.steps/2).toInt()} m" ,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.black),),
          ],),),),
          Card(child: Padding(padding: EdgeInsets.all(20),child:Column(children: [
            Text("今日消耗熱量",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.black),),
            SizedBox(height: 10,),
            Text(core.steps*0.03 > 1 ? core.steps*0.03 > 10 ? core.steps*0.03 > 100 ? "${(core.steps*0.03).toInt()} kcal" :"${(core.steps*0.03).toStringAsFixed(1)} kcal" :"${(core.steps*0.03).toStringAsFixed(2)} kcal": "${(core.steps*30)} cal" ,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.black),),
          ],),),),
        ],),
        SizedBox(height: 20),
        Padding(padding: EdgeInsets.all(20),child: Row(children: [
          Expanded(child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: "設定今日步數",
              border: OutlineInputBorder()
            ),
          )),
          ElevatedButton(onPressed: (){
            int? w = int.tryParse(_controller.text);
            if(w==null) return;
            core.allsteps += w - core.steps;
            core.month.last += w - core.steps;
            core.steps = w;
            core.week.last = w.toDouble();
            core._checkDate();
            core.save();
            _controller.clear();
            core.printAll();
            FocusScope.of(context).unfocus();
          }, child: Text("設定"))
        ],),),
        SizedBox(height: 20,),
        Row(mainAxisAlignment: MainAxisAlignment.center,children: [
          IconButton(onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (builder)=>PP())).then((_){core.init((){setState(() {});});});}, icon: Icon(Icons.emoji_events)),
          SizedBox(width: 10,),
          IconButton(onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (builder)=>WP())).then((_){core.init((){setState(() {});});});}, icon: Icon(Icons.bar_chart)),
        ],)
      ],)],)
    );
  }
}
class WP extends StatefulWidget {
  const WP({super.key});

  @override
  State<WP> createState() => _WPState();
}

class _WPState extends State<WP> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final core = CoreLogic();
  bool _isWeek = true;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this,duration: Duration(milliseconds: 1500));
    _controller.forward();
    core.init((){setState(() {});});
  }
  void tt(bool isWeek){
    setState(() {
      _isWeek=isWeek;
    });
    _controller.reset();
    _controller.forward();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> labels;
    DateTime now = DateTime.now();
    if(_isWeek){
      labels = List.generate(7, (i){
        DateTime d = now.subtract(Duration(days: 6-i));
        return "${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}";
      });
    }else{
      labels = List.generate(12, (i){
        int d = now.month - (11 - i);
        if(d <= 0) d+=12;
        return "$d月";
      });;
    }
    List<double> data = _isWeek ? core.week : core.month;
    return Scaffold(
      appBar: AppBar(title: Text("數據紀錄"),leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),),
      body: ListView(children: [Column(mainAxisAlignment: MainAxisAlignment.center,children: [
        SizedBox(height: 20,),
        SizedBox(height: 200,width: 300,child: AnimatedBuilder(animation: _controller, builder: (context,_)=>CustomPaint(size: Size(MediaQuery.of(context).size.width, 300),painter: LP(data,labels,_controller.value))))
      ],)],),
    );
  }
}

class LP extends CustomPainter {
  final List<double> data;
  final List<String> label;
  final double p;

  LP(this.data, this.label, this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final pt = 20;
    final pb = 40;
    final double ch = size.height - pt - pb;
    final paint = Paint()..color= Colors.blue..strokeWidth=3..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    final dotp = Paint()..color = Colors.white..style=PaintingStyle.fill;
    final dot = Paint()..strokeWidth=2..style=PaintingStyle.stroke;
    final gp = Paint()..strokeWidth=1..color = Colors.grey;
    final path = Path();
    double maxV= data.reduce(max);
    if(maxV ==0)maxV = 5;
    double dx = size.width / (data.length -1);
    for(int i = 0;i<5;i++){
      double y = pt + (ch * (1-i / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
      _drawText(canvas,Offset(-20, y),"${(maxV*i/4)}");
    }
    List<Offset> points=[];
    for(int i = 0; i < data.length;i++){
      double x= i * dx;
      double y= pt + ch -(data[i] * p / maxV*ch);
      Offset cp = Offset(x, y);
      points.add(cp);
      if(i==0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
    for(int i =0;i<points.length;i++){
      var p = points[i];
      canvas.drawCircle(p, 4, dotp);
      canvas.drawCircle(p, 4, dot);
      _drawText(canvas, Offset(points[i].dx, size.height-10), label[i]);
      _drawText(canvas, Offset(points[i].dx, size.height+10), data[i].toString());
    }
  }
  @override
  bool shouldRepaint(LP oldDelegate)=> oldDelegate.p != p || oldDelegate.data != data;

  void _drawText(Canvas canvas, Offset center, String s,{double fontSize = 10,Color color = Colors.grey}) {
    final tp = TextPainter(text:TextSpan(text: s,style: TextStyle(fontSize: fontSize,fontWeight: FontWeight.bold,color: color)),textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(center.dx-tp.width/2, center.dy - tp.height/2));
  }
}


class PP extends StatefulWidget {
  const PP({super.key});

  @override
  State<PP> createState() => _PPState();
}

class _PPState extends State<PP> {
  final core = CoreLogic();
  bool hahaha = true;
  bool hahaha2 = true;
  @override
  void initState() {
    super.initState();
    core.init((){setState(() {});});
  }
  @override
  Widget build(BuildContext context) {
    bool _inUnlock = core.steps >= 10000;
    bool _inUnlock2 = core.allsteps >= 1000000;
    return Scaffold(
      appBar: AppBar(title: Text("勳章介面"),leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),),
      body: ListView(children: [Column(mainAxisAlignment: MainAxisAlignment.center,children: [
        SizedBox(height: 40,),
        Text(_inUnlock ? "finish(每日)" : "${core.steps}/10,000",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.black),),
        SizedBox(height: 40,),
        ElevatedButton(onPressed: (){setState(() {hahaha=!hahaha;});}, child: Container(width: 200,height: 200,decoration: BoxDecoration(shape: BoxShape.circle,gradient: LinearGradient(colors: _inUnlock ? [Colors.amber,Colors.orangeAccent,Colors.yellow] : [Colors.grey,Colors.blueGrey,Colors.grey.shade400],begin: Alignment.topLeft, end: Alignment.bottomRight),boxShadow: [BoxShadow(color: Colors.black45,spreadRadius: 15,blurRadius: 45)]),child: Icon(_inUnlock ? Icons.emoji_events : Icons.lock,color: hahaha ? Colors.white : Colors.black,size: 100,),)),
        Text(_inUnlock ? "finish(每日)" : "${core.steps}/10,000",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.black),),
        SizedBox(height: 20,),
        ElevatedButton(onPressed: (){setState(() {hahaha=!hahaha;});}, child: Container(width: 200,height: 200,decoration: BoxDecoration(shape: BoxShape.circle,gradient: LinearGradient(colors: _inUnlock2 ? [Colors.amber,Colors.orangeAccent,Colors.yellow] : [Colors.grey,Colors.blueGrey,Colors.grey.shade400],begin: Alignment.topLeft, end: Alignment.bottomRight),boxShadow: [BoxShadow(color: Colors.black45,spreadRadius: 15,blurRadius: 45)]),child: Icon(_inUnlock2 ? Icons.emoji_events : Icons.lock,color: hahaha2 ? Colors.white : Colors.black,size: 100,),))
      ],)],),
    );
  }
}
