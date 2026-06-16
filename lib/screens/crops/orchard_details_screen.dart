import 'package:flutter/material.dart';

class OrchardDetailsScreen extends StatefulWidget {
  // Pass the global language state from the sidebar/drawer when navigating to this screen
  final bool initialIsEnglish;

  const OrchardDetailsScreen({
    super.key, 
    this.initialIsEnglish = true,
  });

  @override
  State<OrchardDetailsScreen> createState() => _OrchardDetailsScreenState();
}

class _OrchardDetailsScreenState extends State<OrchardDetailsScreen> {
  // Language State: Dynamic track based on global initial state
  late bool isEnglish;

  // Scroll Controller to track scroll position and change shape dynamically
  final ScrollController _scrollController = ScrollController();
  bool _isCircleWeather = false;

  // Static Weather Data (Layyah City Details)
  final String temperature = "42°C";
  final String weatherConditionEng = "Sunny & Hot";
  final String weatherConditionUrdu = "دھوپ اور شدید گرمی";
  final String windSpeedEng = "14 km/h";
  final String windSpeedUrdu = "۱۴ کلومیٹر فی گذشتہ";
  final String humidity = "28%";

  // Complete Detailed Orchard Data with explicit icons and full agricultural info
  final List<Map<String, dynamic>> orchardsData = [
    {
      "id": "citrus",
      "icon": "🍊", // Kinnu
      "name_en": "Citrus (Kinnu)",
      "name_ur": "کینو / ترشاوہ پھل",
      "desc_en": "Layyah's sandy loam soil is highly suitable for high-quality Citrus production. Focus on nitrogen fertilizers and deep irrigation cycles during hot summer months to prevent fruit drop. Apply dynamic fertilizer doses during late winter.",
      "desc_ur": "لیہ کی ریتلی لومی مٹی اعلیٰ معیار کے کینو کی پیداوار کے لیے انتہائی موزوں ہے۔ گرمیوں کے مہینوں میں پھل گرنے سے بچانے کے لیے نائٹروجن کھادوں اور گہرے آبپاشی کے چکروں پر توجہ دیں۔ سردیوں کے آخر میں کھاد کی متحرک خوراکیں استعمال کریں۔",
    },
    {
      "id": "guava",
      "icon": "🍐", // Guava/Amrood
      "name_en": "Guava (Amrood)",
      "name_ur": "امرود",
      "desc_en": "Guava orchards require careful management against fruit fly attacks. Implement pheromone traps and maintain balanced watering to ensure crisp texture and optimal fruit size. Regular organic manure additions help sustain tree health.",
      "desc_ur": "امرود کے باغات کو پھل کی مکھی کے حملوں کے خلاف محتاط انتظام کی ضرورت ہوتی ہے۔ پھل کی کرکرا پن اور بہترین سائز کو یقینی بنانے کے لیے فیرومون ٹریپس لگائیں اور متوازن پانی برقرار رکھیں۔ نامیاتی کھاد کا باقاعدہ استعمال پودے کی صحت برقرار رکھتا ہے۔",
    },
    {
      "id": "mosambi",
      "icon": "🟢", // Sweet Lime
      "name_en": "Mosambi (Sweet Lime)",
      "name_ur": "موسمبی",
      "desc_en": "Requires well-drained loamy soil. Monitor regularly for citrus psylla and citrus canker. Zinc sulphate sprays during early stages can significantly improve sweetness and overall yield.",
      "desc_ur": "بہترین نقاس والی لومی مٹی کی ضرورت ہوتی ہے۔ سیٹرس سائلا اور سیٹرس کینکر کے لیے باقاعدگی سے نگرانی کریں۔ ابتدائی مراحل کے دوران زنک سلفیٹ کا سپرے مٹھاس اور مجموعی پیداوار میں نمایاں اضافہ کر سکتا ہے۔",
    },
    {
      "id": "pomegranate",
      "icon": "🍎", // Pomegranate/Anar
      "name_en": "Pomegranate (Anar)",
      "name_ur": "انار",
      "desc_en": "Thrives beautifully in hot climates like Layyah. Protect fruits from heavy direct sun scorching using paper wrapping, and manage regular low-volume irrigation to avoid skin cracking during dry spells.",
      "desc_ur": "لیہ جیسے گرم موسم میں یہ بہت شاندار پروان چڑھتا ہے۔ کاغذ کی لپیٹ کا استعمال کرتے ہوئے پھلوں کو تیز دھوپ سے بچائیں، اور خشک موسم کے دوران چھلکے کو پھٹنے سے بچانے کے لیے باقاعدہ اور کم مقدار میں آبپاشی کا انتظام کریں۔",
    },
    {
      "id": "lemon",
      "icon": "🍋", // Lemon
      "name_en": "Lemon (Limoo)",
      "name_ur": "لیموں",
      "desc_en": "Highly sensitive to heavy frost but gives excellent yield in warm summer weather. Ensure constant soil moisture during flowering stage to prevent flower dropping and enhance juice content.",
      "desc_ur": "شدید کہرے اور سردی کے لیے انتہائی حساس ہے لیکن گرمیوں کے موسم میں بہترین پیداوار دیتا ہے۔ پھول آنے کے عمل کے دوران پھولوں کو گرنے سے بچانے اور رس بڑھانے کے لیے مٹی میں نمی کا تسلسل یقینی بنائیں۔",
    },
    {
      "id": "orange",
      "icon": "🍊", // Orange Malta
      "name_en": "Orange (Malta)",
      "name_ur": "مالٹا",
      "desc_en": "Prefers standard direct sunlight and rich organic matter. Regular pruning after harvest increases next season's yield, opens up canopy light interception, and keeps branches safe from pest infestations.",
      "desc_ur": "یہ براہ راست سورج کی روشنی اور بھرپور نامیاتی مادے کو پسند کرتا ہے۔ کٹائی کے بعد باقاعدگی سے کانٹ چھانٹ اگلے سیزن کی پیداوار میں اضافہ کرتی ہے، پودوں تک روشنی پہنچاتی ہے اور شاخوں کو کیڑوں کے حملوں سے محفوظ رکھتی ہے۔",
    }
  ];

  @override
  void initState() {
    super.initState();
    isEnglish = widget.initialIsEnglish;
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 100) {
        if (!_isCircleWeather) {
          setState(() {
            _isCircleWeather = true;
          });
        }
      } else {
        if (_isCircleWeather) {
          setState(() {
            _isCircleWeather = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant OrchardDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync language if parent sidebar switches states seamlessly
    if (oldWidget.initialIsEnglish != widget.initialIsEnglish) {
      setState(() {
        isEnglish = widget.initialIsEnglish;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEnglish ? "Orchard Management" : "باغات کا انتظام",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Manual toggle button in AppBar just in case
          TextButton(
            onPressed: () {
              setState(() {
                isEnglish = !isEnglish;
              });
            },
            child: Text(
              isEnglish ? "اردو" : "English",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable List View of Fruits
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 170, 16, 30),
            itemCount: orchardsData.length,
            itemBuilder: (context, index) {
              final fruit = orchardsData[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[500]!.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      fruit["icon"],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    isEnglish ? fruit["name_en"] : fruit["name_ur"],
                    textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    isEnglish ? "Tap to view complete tips" : "مکمل مشورے دیکھنے کے لیے کلک کریں",
                    textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          const Divider(),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              isEnglish ? "Water & Fertilizer Details:" : "کھاد اور پانی کی تفصیلات:",
                              textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isEnglish ? fruit["desc_en"] : fruit["desc_ur"],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                            textAlign: isEnglish ? TextAlign.justify : TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Animated Floating Weather Card (Transforms and switches sides instantly based on state)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            top: 16,
            // English circle goes to the Right side, Urdu circle goes to the Left side
            left: _isCircleWeather 
                ? (isEnglish ? null : 16) 
                : 16,
            right: _isCircleWeather 
                ? (isEnglish ? 16 : null) 
                : 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: _isCircleWeather ? 65 : MediaQuery.of(context).size.width - 32,
              height: _isCircleWeather ? 65 : 130,
              padding: EdgeInsets.all(_isCircleWeather ? 4 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: _isCircleWeather ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: _isCircleWeather ? null : BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[900]!.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _isCircleWeather
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("☀️", style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        FittedBox(
                          child: Text(
                            temperature,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isEnglish ? "Layyah City Weather" : "لیہ شہر کا موسم",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEnglish ? weatherConditionEng : weatherConditionUrdu,
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: isEnglish ? MainAxisAlignment.start : MainAxisAlignment.end,
                                children: isEnglish 
                                  ? [
                                      const Icon(Icons.air, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text("Wind: $windSpeedEng", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.water_drop, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text("Humidity: $humidity", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ]
                                  : [
                                      Text("نمی: $humidity", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.water_drop, color: Colors.white70, size: 14),
                                      const SizedBox(width: 12),
                                      Text("ہوا: $windSpeedUrdu", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.air, color: Colors.white70, size: 14),
                                    ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "☀️",
                              style: TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              temperature,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}