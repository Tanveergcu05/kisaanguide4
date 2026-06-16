import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:weather/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/config/app_config.dart';

class AddCropScreen extends StatefulWidget {
  final bool isUrdu;

  const AddCropScreen({super.key, required this.isUrdu});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> with TickerProviderStateMixin {
  late WeatherFactory _wf;
  Weather? _currentWeather;
  bool _isLoadingWeather = true;
  bool _isOffline = false;
  
  int _selectedCropIndex = 0;
  late TabController _tabController;

  // Premium Agriculture Theme Color Palette (Green & Yellow Scheme)
  static const Color primaryGreen = Color(0xFF2E6F40);   // Deep Premium Rich Green
  static const Color accentYellow = Color(0xFFFBC02D);   // Vibrant Mustard Gold/Yellow
  static const Color lightYellow = Color(0xFFFFFDE7);    // Soft Background Cream Yellow
  static const Color darkGrey = Color(0xFF2D312E);       // Professional Text Grey

  final String _apiKey = AppConfig.openWeatherApiKey;

  final List<Map<String, dynamic>> _crops = [
    {"name": "Wheat", "urdu": "گندم", "icon": Icons.grain},
    {"name": "Cotton", "urdu": "کپاس", "icon": Icons.cloud_circle_rounded},
    {"name": "Sesame", "urdu": "تل", "icon": Icons.spa},
    {"name": "Maize", "urdu": "مکئی", "icon": Icons.grid_view_rounded},
    {"name": "Rice", "urdu": "دھان", "icon": Icons.eco},
    {"name": "Sugarcane", "urdu": "گنا", "icon": Icons.reorder_rounded},
  ];

  // Highly Intensive & Exhaustive Technical Agronomy Data (50+ Lines Target per Crop)
  final Map<String, Map<String, Map<String, dynamic>>> _cropDetailsData = {
    "Wheat": {
      "en": {
        "kasht": "• Complete Laser Land Leveling is strictly recommended to save 30% water and ensure 100% uniform seed germination across the acre.\n"
                 "• Optimum Sowing Timeline: November 1 to November 20 (Peak yield window). Sowing after December 10 causes a drastic yield decline of 15-20 kg per acre daily.\n"
                 "• Authorized Seed Varieties: Akbar-19, Dilkash-20, Bhakkar-20, Ghazi-19, and Subhani-21. Avoid using rusted/old seeds from last 3 seasons.\n"
                 "• Recommended Seed Rate Matrix:\n"
                 "   - Timely Sowing (Nov 1-20): Use exactly 45-50 kg per acre.\n"
                 "   - Late Sowing (Dec onwards): Increase seed rate to 55-60 kg per acre to counter low tillering.\n"
                 "• Mandatory Chemical Seed Treatment: Treat seeds with Thiophanate-methyl or Imidacloprid + Tebuconazole @ 2.5 grams per 1 kg of seed to eradicate loose smut and seed-borne pathogens permanently.\n"
                 "• Sowing Methodologies:\n"
                 "   - Automatic Seed-cum-Fertilizer Drill method is preferred over broadcasting for precise depth (2 to 2.5 inches).\n"
                 "   - In rainfed zones, use the 'Rabi Drill' to preserve soil moisture.\n"
                 "• Soil Preparation Dynamics: Plow the soil 2-3 times with a standard cultivator followed by a heavy plank (Suhaga) to crush all hard clods.\n"
                 "• Maintain a target plant population of 1.2 to 1.5 million healthy plants per acre for maximizing structural output.",
        "pani": "• Wheat crop requires 4 to 5 critical irrigations under normal climatic conditions, managed carefully at biological growth stages:\n"
                 "• Irrigation 1 (Crown Root Initiation stage / Kor Water): Apply precisely 20-25 days after sowing. Skipping this destroys the structural root base and drops yield by 35%.\n"
                 "• Irrigation 2 (Tillering Stage): Apply 40-45 days after sowing. Encourages maximum sub-stem generation.\n"
                 "• Irrigation 3 (Late Jointing / Booting Stage): Apply 70-75 days after sowing. Critical for head development; moisture stress here shortens spikes.\n"
                 "• Irrigation 4 (Flowering / Heading Stage): Apply 90-95 days after sowing. Ensures uniform fertilization of grains.\n"
                 "• Irrigation 5 (Milking / Dough Stage): Apply 110-115 days after sowing. Stress results in shriveled, thin grains.\n"
                 "• Crucial Warning: Strictly monitor high wind forecasts before applying the 4th and 5th irrigations to avoid catastrophic lodging (crop falling down).\n"
                 "• In case of high rainfall seasons, reduce irrigation frequency but ensure internal drainage channels are fully functional to prevent water stagnation.",
        "khaad": "• Fertilizer plan must be based on soil texture analysis. Standard recommendation for average fertility soils:\n"
                 "• At Land Preparation / Sowing: Apply 1 bag of DAP (Diammonium Phosphate) + 1 bag of SOP (Sulphate of Potash) per acre to ensure immediate root phosphorus accessibility.\n"
                 "• First Irrigation (Kor Water): Apply 1 bag of high-grade granular Urea to boost early vegetative growth.\n"
                 "• Second Irrigation: Apply another 1 bag or 1.5 bags of Urea depending on crop color.\n"
                 "• Micronutrient Application for Critical Deficiencies:\n"
                 "   - Zinc Deficiency: Apply 5 kg of Zinc Sulphate (33% powdered) or 10 kg of Zinc Sulphate (21%) mixed with dry soil during first watering.\n"
                 "   - Boron Deficiency: Apply 3 kg of Borax (10.5%) at land preparation to prevent sterile florets and improve grain weight.\n"
                 "• Split Application Rule: Never apply all Nitrogenous/Urea fertilizers at once as it causes heavy leaching and volatilization losses.\n"
                 "• Late-applied nitrogen after the heading stage is counter-productive and only increases vegetative biomass instead of actual grain yield.",
        "spray": "• Weed management is divided into Pre-emergence and Post-emergence phases:\n"
                 "• Pre-emergence Strategy: Spray Pendimethalin @ 1 Liter per acre within 24 to 48 hours of sowing in adequate moisture (Wattr) conditions.\n"
                 "• Post-emergence Broad-leaved Weeds control (Bathu, Maina, Lehli): Spray Pyroxasulfone or Carfentrazone-ethyl 40-50 days after sowing.\n"
                 "• Post-emergence Narrow-leaved/Grassy Weeds control (Dumbi Sitti, जंगली جئی): Spray Clodinafop-propargyl @ 100 grams per acre or Pinoxaden after the first irrigation when weeds are at 2-3 leaf stage.\n"
                 "• Precautions for Chemical Spraying:\n"
                 "   - Use T-Jet or Flat Fan nozzles exclusively for uniform coverage; avoid round cone nozzles.\n"
                 "   - Ensure a minimum water volume of 100 to 120 liters per acre.\n"
                 "   - Do not spray when leaves are wet with morning dew or when winds exceed 10 km/h.\n"
                 "• Regular scouting must be done every 3 days during January and February to spot initial pest populations.",
        "bimariyan": [
          {
            "name": "Yellow Rust (Puccinia striiformis)",
            "symptoms": "Yellow/orange linear pustules appear parallel to leaf veins, turning into powder when touched. Thrives in cool (10-20°C) damp weather.",
            "treatment": "Immediate foliar spray of Tebuconazole + Trifloxystrobin (Nativo @ 65 grams/acre) or Tilt @ 200 ml mixed in 100 Liters of water."
          },
          {
            "name": "Loose Smut (Ustilago nuda)",
            "symptoms": "Entire grain head turns into a dark, black powdery mass of fungal spores covered by a thin membrane which breaks down during wind blowing.",
            "treatment": "Irreversible in field. Prevention is the only cure via seed dressing using Flutriafol or carboxin before sowing."
          },
          {
            "name": "Wheat Aphid (Sust Tila)",
            "symptoms": "Small green/black insects cluster on spikes and suck sap, excreting honeydew that leads to black sooty mold and severely minimizes grain size.",
            "treatment": "Spray Imidacloprid 25% WP @ 60 grams or Thiamethoxam @ 24 grams per acre if pest density crosses Economic Threshold Level (ETL) of 15 aphids per spike."
          }
        ]
      },
      "ur": {
        "kasht": "• ایکڑ میں پانی کی 30 فیصد بچت اور 100 فیصد یکساں اگاؤ کو یقینی بنانے کے لیے لیزر لینڈ لیولنگ کا استعمال انتہائی لازمی ہے۔\n"
                 "• گندم کی کاشت کا بہترین اور موزوں ترین وقت 1 نومبر سے 20 نومبر تک ہے۔ 10 دسمبر کے بعد کاشت کرنے سے فی ایکڑ پیداوار میں روزانہ 15 سے 20 کلوگرام کی بھاری کمی واقع ہوتی ہے۔\n"
                 "• منظور شدہ اور ترقی دادا اقسام: اکبر-19، دلکش-20، بھکر-20، غازی-19، اور سبحانی-21 کا استعمال کریں۔ پچھلے 3 سال کا پرانا اور کنگی زدہ بیج ہرگز استعمال نہ کریں۔\n"
                 "• وقت کے مطابق شرح بیج کی تفصیل:\n"
                 "   - بروقت کاشت (1 تا 20 نومبر): 45 سے 50 کلوگرام فی ایکڑ بیج ڈالیں۔\n"
                 "   - پچھیتی کاشت (دسمبر): گرتے ہوئے جھاڑ کو پورا کرنے کے لیے بیج کی مقدار بڑھا کر 55 سے 60 کلوگرام کریں۔\n"
                 "• بیج کو زہر لگانا (Mandatory Dressing): کانگڑی اور دیگر فنگس بیماریوں کے مکمل خاتمے کے لیے بیج کو کاشت سے پہلے تھیوفینیٹ میتھائل یا امیڈاکلوپرڈ + ٹیبوکونازول بحساب 2.5 گرام فی کلوگرام بیج لازمی لگائیں۔\n"
                 "• کاشت کے طریقے:\n"
                 "   - چھٹے کے طریقے کی بجائے آٹومیٹک فرٹیلائزر-کم-سیڈ ڈرل کا طریقہ اپنائیں تاکہ بیج 2 سے 2.5 انچ کی یکساں گہرائی پر گرے۔\n"
                 "   - بارانی علاقوں میں رطوبت بچانے کے لیے ربیع ڈرل کا استعمال کریں۔\n"
                 "• زمین کی تیاری: 2 سے 3 بار عام ہل چلانے کے بعد بھاری سہاگا پھیریں تاکہ ڈھیلے ٹوٹ جائیں اور مٹی نرم ہو جائے۔\n"
                 "• فی ایکڑ پودوں کی تعداد 12 سے 15 لاکھ تک برقرار رکھیں تاکہ زیادہ سے زیادہ جھاڑ بن سکے۔",
        "pani": "• گندم کی فصل کو عام موسمی حالات میں 4 سے 5 اہم پانیوں کی ضرورت ہوتی ہے، جنہیں پودے کے نازک مراحل پر دینا لازمی ہے:\n"
                 "• پہلا پانی (تاجی جڑیں نکلنے کا مرحلہ / کور کا پانی): بوائی کے ٹھیک 20 سے 25 دن بعد لگائیں۔ اس پانی میں تاخیر سے جڑیں کمزور رہ جاتی ہیں اور پیداوار 35 فیصد تک گر جاتی ہے۔\n"
                 "• دوسرا پانی (شاخیں نکلنے کا وقت / Tillering): کاشت کے 40 سے 45 دن بعد لگائیں۔ یہ پودے کو زیادہ تنے بنانے میں مدد دیتا ہے۔\n"
                 "• تیسرا پانی (گوبھ کا مرحلہ / Booting): کاشت کے 70 سے 75 دن after لگائیں۔ یہ سٹہ بننے کا مرحلہ ہے، اس وقت سوکا آنے سے سٹہ چھوٹا رہ جاتا ہے۔\n"
                 "• چوتھا پانی (سٹہ نکلتے وقت / Heading): کاشت کے 90 سے 95 دن بعد لگائیں تاکہ دانوں کی بناوٹ یکساں ہو۔\n"
                 "• پانچواں پانی (دودھیا حالت / Milking): کاشت کے 110 سے 115 دن بعد لگائیں۔ پانی نہ ملنے سے دانہ پچک جاتا ہے۔\n"
                 "• اہم ترین تنبیہ: چوتھا اور پانچواں پانی لگانے سے پہلے محکمہ موسمیات کی تیز ہوا کی پیشگوئی لازمی دیکھیں، ورنہ فصل گر (Lodging) جائے گی اور شدید نقصان ہو گا۔\n"
                 "• زیادہ بارشوں کی صورت میں پانی کا وقفہ بڑھا دیں لیکن کھیت میں پانی کھڑا نہ ہونے دیں، نکاس کا انتظام رکھیں۔",
        "khaad": "• کھادوں کا متوازن استعمال زمین کے تجزیے کی روشنی میں ہونا چاہیے۔ اوسط زرخیز زمینوں کے لیے تجویز کردہ پلان:\n"
                 "• زمین کی تیاری / بجائی کے وقت: 1 بوری ڈی اے پی (DAP) + 1 بوری ایس او پی (پوٹاشیم سلفیٹ) فی ایکڑ ڈالیں تاکہ جڑوں کو فاسفورس فوراً مل سکے۔\n"
                 "• پہلے پانی پر (کور کا پانی): پودے کی تیزی سے بڑھوتری کے لیے 1 بوری یوریا کھاد لازمی دیں۔\n"
                 "• دوسرے پانی پر: فصل کی رنگت دیکھ کر مزید 1 سے 1.5 بوری یوریا کھاد کا استعمال کریں۔\n"
                 "• مائیکرو نیوٹرینٹس (اجزائے صغیرہ) کا استعمال:\n"
                 "   - زنک کی کمی: پہلے پانی پر 5 کلوگرام زنک سلفیٹ (33 فیصد) یا 10 کلوگرام زنک سلفیٹ (21 فیصد) خشک مٹی میں ملا کر چھٹا کریں۔\n"
                 "   - بورون کی کمی: سٹے میں دانوں کی زرخیزی بڑھانے کے لیے زمین کی تیاری میں 3 کلوگرام بوریکس (10.5 فیصد) لازمی ڈالیں۔\n"
                 "• کھاد کا اصول: تمام نائٹروجن (یوریا) کھاد ایک ہی وقت میں مت دیں، اس سے کھاد ضائع ہو جاتی ہے اور پودا زیادہ نازک ہو جاتا ہے۔\n"
                 "• سٹہ نکلنے کے بعد یوریا کھاد دینے کا کوئی فائدہ نہیں ہوتا، اس سے صرف پتے بڑھتے ہیں دانے مضبوط نہیں ہوتے۔",
        "spray": "• جڑی بوٹیوں کا تدارک دو مراحل (اگاؤ سے پہلے اور اگاؤ کے بعد) میں کیا جاتا ہے:\n"
                 "• اگاؤ سے پہلے (Pre-emergence): کاشت کے 24 سے 48 گھنٹے کے اندر وتر حالت میں پینڈیمیٹالین بحساب 1 لیٹر فی ایکڑ اسپرے کریں۔\n"
                 "• چوڑے پتے والی جڑی بوٹیاں (باتھو, مینا، لیہلی، سیندجی): ان کے خاتمے کے لیے کاشت کے 40 سے 50 دن بعد پائروکساسلفون یا کارفینٹرازون-ایتھائل کا اسپرے کریں۔\n"
                 "• نوکیلے پتے والی جڑی بوٹیاں (دمبی سٹی، جنگلی جئی): پہلے پانی کے بعد جب جڑی بوٹیاں 2 سے 3 پتوں پر ہوں، کلوڈینا فاپ-پروپارجل 100 گرام یا پینوکسادین کا اسپرے کریں۔\n"
                 "• اسپرے کے دوران احتیاطی تدابیر:\n"
                 "   - یکساں پھیلاؤ کے لیے ہمیشہ فلیٹ فین یا ٹی-جیٹ نوزل استعمال کریں۔ گول کون نوزل ہرگز استعمال نہ کریں۔\n"
                 "   - پانی کی مقدار کم از کم 100 سے 120 لیٹر فی ایکڑ ہونی چاہیے۔\n"
                 "   - شبنم کی حالت میں یا 10 کلومیٹر فی گھنٹہ سے تیز ہوا میں اسپرے نہ کریں۔\n"
                 "• جنوری اور فروری میں ہر 3 دن بعد کھیت کا معائنہ (Pest Scouting) کریں تاکہ سست تیلے کا بروقت پتہ چل سکے۔",
        "bimariyan": [
          {
            "name": "پیلی کنگی (Yellow Rust)",
            "symptoms": "پتوں پر پیلے اور نارنجی رنگ کی لمبی دھاریاں بنتی ہیں جن کو چھونے پر پاؤڈر ہاتھ پر لگتا ہے۔ یہ 10 سے 20 ڈگری درجہ حرارت اور نمی میں پھیلتی ہے۔",
            "treatment": "بیماری نظر آتے ہی ٹیبوکونازول + ٹرائی فلواکسی سٹروبن (Nativo @ 65 گرام) یا ٹلٹ (Tilt @ 200 ملی لیٹر) 100 لیٹر پانی میں ملا کر اسپرے کریں۔"
          },
          {
            "name": "کانگڑی (Loose Smut)",
            "symptoms": "گندم کا سٹہ دانے بننے کی بجائے سیاہ پاؤڈر (فنگس سپورز) کی شکل اختیار کر لیتا ہے اور ہوا سے یہ پاؤڈر دوسرے پودوں میں پھیل جاتا ہے۔",
            "treatment": "کھیت میں اس کا علاج ممکن نہیں ہے۔ اس کا واحد حل بوائی سے پہلے بیج کو فلوٹریا فول یا کاربوکسن جیسی فنگسائڈ دوائی لگانا ہے۔"
          },
          {
            "name": "سست تیلا (Wheat Aphid)",
            "symptoms": "چھوٹے سبز یا سیاہ کیڑے سٹوں پر حملے کرتے ہیں اور رس چوستے ہیں، جس سے لیسدار مادہ نکلتا ہے اور دانے کا سائز بالکل چھوٹا رہ جاتا ہے۔",
            "treatment": "اگر تیلے کی تعداد معاشی حد (15 کیڑے فی سٹہ) سے تجاوز کر جائے تو امیڈاکلوپرڈ 25٪ WP بحساب 60 گرام یا تھایامیتھوکسام 24 گرام فی ایکڑ اسپرے کریں۔"
          }
        ]
      }
    },
    "Cotton": {
      "en": {
        "kasht": "• Laser land leveling is essential to guarantee uniform irrigation depth and prevent water pooling which causes root rot.\n"
                 "• Optimal Sowing Time: Core Bt varieties from April 15 to May 31. Early sowing in March is highly susceptible to pink bollworm.\n"
                 "• High-Yield Approved Seed Varieties: BS-15, CKC-3, MNH-1020, and FH-444. Ensure 100% certified seed sourcing.\n"
                 "• Seeding Rate Matrix: Delinted seeds should be used at 6 to 8 kg per acre for manual dibbling, and 10 kg for mechanical drill sowing.\n"
                 "• Mandatory Chemical Seed Treatment: Treat seeds with Imidacloprid 70 WS @ 5 grams per kg + Carboxin to protect against early sucking pests for the first 30 days.\n"
                 "• Recommended Planting Geometry: Row-to-row spacing must be 2.5 feet to 3 feet, and plant-to-plant distance should be strictly kept at 9 to 12 inches.\n"
                 "• Sowing Method: Sowing on beds and furrows using a mechanical bed-planter reduces water usage by 40% and enhances germination percentage.\n"
                 "• Maintain a strict plant density of 17,500 to 22,000 healthy standing plants per acre to optimize solar interception.",
        "pani": "• Cotton is highly sensitive to irrigation timing; both over-irrigation and severe drought reduce yield significantly.\n"
                 "• Bed-Sown Irrigation Regime: First irrigation must be given 3 to 4 days after sowing to facilitate seed sprouting.\n"
                 "• Subsequent Irrigations: Apply water every 6 to 9 days during dry summer cycles, and every 12 to 15 days in autumn.\n"
                 "• Critical Peak Growth Stages: Flowering and Boll Development stages require uninterrupted moisture. Water stress here causes massive boll dropping.\n"
                 "• Final Water Management: Stop applying water completely around mid-October to allow the mature bolls to dry and split open safely.\n"
                 "• Stagnant Water Care: If monsoon rains flood the field, drain out the excess water within 12 hours to save plants from chemical wilting.",
        "khaad": "• Complete Macro-Nutrient recommendation for structural cotton balance:\n"
                 "• At Bed Preparation: Apply 1.5 bags of DAP + 1 bag of SOP + 1 bag of Ammonium Sulphate per acre.\n"
                 "• Vegetative Nitrogen Splitting: Apply 2.5 to 3 bags of Urea per acre, divided across 4 split doses matching alternate irrigations starting from day 35.\n"
                 "• Boron Foliar Supplementation: Spray Boric acid (20% Solubor) @ 200 grams per acre during flowering to reduce premature bud dropping.\n"
                 "• Zinc Supplementation: Apply 5 kg of Zinc Sulphate (33%) at day 40 if leaves exhibit typical interveinal chlorosis (whitish spots).\n"
                 "• Excessive late application of nitrogen must be avoided as it causes excessive vegetative growth and attracts whitefly infestations.",
        "spray": "• Sucking pest management requires constant pest scouting using a traditional yellow sticky trap setup:\n"
                 "• Whitefly (Safed Makhi) Management: Spray Pyriproxyfen @ 400 ml or Spirotetramat if the population crosses the ETL of 5 adults/leaf.\n"
                 "• Jassid (Chust Tila) Management: Spray Flonicamid (Ulala) @ 60-80 grams per acre immediately when the ETL of 1 nymph per leaf is observed.\n"
                 "• Pink Bollworm (Gulabi Sundi) Control: Install Pheromone Traps @ 4-6 traps per acre. Spray Gamma-Cyhalothrin or Spetoram when infested bolls touch 5%.\n"
                 "• Resistance Management Rule: Never repeat the same insecticide chemical group consecutively; always alternate modes of action.",
        "bimariyan": [
          {
            "name": "Cotton Leaf Curl Virus (CLCuV)",
            "symptoms": "Leaves curl upwards or downwards, veins become severely thickened, and a leaf-like growth (enation) develops on the underside.",
            "treatment": "No direct cure. Eradicate whiteflies strictly using Flonicamid as they act as vectors. Pull out and bury infected plants immediately."
          },
          {
            "name": "Bacterial Blight (Angular Leaf Spot)",
            "symptoms": "Water-soaked angular brown spots appear on leaves, which turn black and progress along the veins, causing severe defoliation.",
            "treatment": "Spray Copper Oxychloride @ 500 grams + Streptomycin @ 50 grams mixed in 100 Liters of water per acre."
          }
        ]
      },
      "ur": {
        "kasht": "• پانی کے یکساں پھیلاؤ کو یقینی بنانے اور جڑوں کے گلنے کی بیماری سے بچاؤ کے لیے لیزر لینڈ لیولنگ کا استعمال لازمی ہے۔\n"
                 "• کپاس کی کاشت کا بہترین وقت: بی ٹی (Bt) اقسام کے لیے 15 اپریل سے 31 مئی تک ہے۔ مارچ میں اگیتی کاشت گلابی سنڈی کا شکار ہوتی ہے۔\n"
                 "• زیادہ پیداوار دینے والی اقسام: بی ایس-15، سی کے سی-3، ایم این ایچ-1020، اور ایف ایچ-444 کا تصدیق شدہ بیج استعمال کریں۔\n"
                 "• شرح بیج: بغیر بر والا بیج (Delinted) چھابے/چوپے کے لیے 6 سے 8 کلوگرام اور ڈرل کی صورت میں 10 کلوگرام فی ایکڑ استعمال کریں۔\n"
                 "• بیج کو زہر لگانا: ابتدائی 30 دنوں تک رس چوسنے والے کیڑوں سے بچاؤ کے لیے بیج کو بوائی سے پہلے امیڈاکلوپرڈ 70 WS بحساب 5 گرام فی کلو بیج لازمی لگائیں۔\n"
                 "• پودوں کا درمیانی فاصلہ: لائن سے لائن کا فاصلہ 2.5 سے 3 فٹ اور پودے سے پودے کا فاصلہ ہر حال میں 9 سے 12 انچ رکھیں۔\n"
                 "• کاشت کا طریقہ: کھیلیاں بنانے والی مشین (Bed Planter) کے ذریعے کھیلوں پر کاشت کریں، اس سے 40 فیصد پانی بچتا ہے اور اگاؤ بہتر ہوتا ہے۔\n"
                 "• فی ایکڑ پودوں کی تعداد: زیادہ سے زیادہ پیداوار کے لیے فی ایکڑ 17,500 سے 22,000 صحت مند پودے برقرار رکھیں۔",
        "pani": "• کپاس پانی کی کمی اور زیادتی دونوں کے لیے بہت حساس ہے؛ دونوں صورتوں میں پھول اور ٹینڈے گر جاتے ہیں۔\n"
                 "• کھیلوں پر کاشت کا پانی: پہلا پانی بوائی کے ٹھیک 3 سے 4 دن بعد لگائیں تاکہ بیج کا اگاؤ جلدی ہو سکے۔\n"
                 "• بعد کے پانی: شدید گرمی کے مہینوں میں ہر 6 سے 9 دن بعد اور ستمبر-اکتوبر میں 12 سے 15 دن کے وقفے پر پانی دیں۔\n"
                 "• نازک مراحل (Critical Stages): پھول آنے اور ٹینڈا بننے کے دوران فصل کو سوکا ہرگز نہ لگنے دیں، ورنہ ٹینڈے وقت سے پہلے گر جائیں گے۔\n"
                 "• آخری پانی: اکتوبر کے وسط میں پانی لگانا بند کر دیں تاکہ تیار ٹینڈے اچھی طرح سوکھ کر کھل سکیں۔\n"
                 "• فالتو پانی کا نکاس: مانسون کی بارشوں کا پانی اگر کھیت میں کھڑا ہو جائے تو اسے 12 گھنٹے کے اندر نکالیں ورنہ پودے مرجھا کر سوکھ جائیں جائیں۔",
        "khaad": "• کپاس کی بہتر بڑھوتری اور ٹینڈوں کے سائز کے لیے کھاد کا مکمل متوازن پلان:\n"
                 "• کھیلیاں بناتے وقت: 1.5 بوری ڈی اے پی + 1 بوری ایس او پی (پوٹاش) + 1 بوری امونیم سلفیٹ فی ایکڑ ڈالیں۔\n"
                 "• یوریا کھاد کا استعمال: بوائی کے 35 دن بعد سے شروع کر کے اگلی 4 آبپاشیوں کے ساتھ کل 2.5 سے 3 بوری یوریا قسطوں میں دیں۔\n"
                 "• بورون کا اسپرے: پھول آتے وقت بورک ایسڈ (Solubor 20%) بحساب 200 گرام فی ایکڑ اسپرے کریں تاکہ ڈوڈی گرنے کا عمل رک سکے۔\n"
                 "• زنک کی کمی کا علاج: بوائی کے 40 دن بعد 5 کلو زنک سلفیٹ (33 فیصد) فلڈ کریں اگر پتوں کا رنگ سفید یا پیلا پڑ رہا ہو۔\n"
                 "• ستمبر کے بعد یوریا کھاد کا استعمال ہرگز نہ کریں، اس سے سفید مکھی اور لشکری سنڈی کا حملہ شدید ہو جاتا ہے۔",
        "spray": "• رس چوسنے والے کیڑوں کے کنٹرول کے لیے پیلے رنگ کے چمکیلے کارڈ (Sticky Traps) کھیت میں لگائیں اور پیسٹ سکاؤٹنگ کریں:\n"
                 "• سفید مکھی (Whitefly): اگر تعداد معاشی حد (5 بالغ یا بچے فی پتہ) تک پہنچ جائے تو پائری پروکسیفن 400 ملی لیٹر یا سپائروٹیٹرمیٹ کا اسپرے کریں۔\n"
                 "• چست تیلا (Jassid): پتے پر ایک بھی بچہ نظر آنے کی صورت میں فلونیکا مڈ (Ulala) بحساب 60 سے 80 گرام فی ایکڑ فوراً اسپرے کریں۔\n"
                 "• گلابی سنڈی (Pink Bollworm): کھیت میں 4 سے 6 فیرومون ٹریپس لگائیں۔ حملہ 5 فیصد ہونے پر گاما-سائھالوتھرین یا اسپیٹورام کا اسپرے کریں۔\n"
                 "• اہم اصول: ایک ہی کیڑے مار زہر کا اسپرے لگاتار دوبارہ نہ کریں، کیمیکل گروپ بدل بدل کر اسپرے کریں۔",
        "bimariyan": [
          {
            "name": "پتہ مروڑ وائرس (CLCuV)",
            "symptoms": "پتے اوپر یا نیچے کی طرف مڑ جاتے ہیں، پتوں کی رگیں موٹی اور بدشکل ہو جاتی ہیں اور پتے کے نیچے ایک چھوٹا پتا نما ابھار بن جاتا ہے۔",
            "treatment": "اس کا کوئی براہ راست علاج نہیں ہے۔ سفید مکھی کو فلونیکا مڈ سے کنٹرول کریں کیونکہ وہی یہ وائرس پھیلاتی ہے۔ بیمار پودوں کو اکھاڑ کر دبا دیں۔"
          },
          {
            "name": "بیکٹیریل جھلساؤ (Angular Leaf Spot)",
            "symptoms": "پتوں پر پانی کے دھبے بنتے ہیں جو بعد میں کونے دار بھورے اور کالے ہو جاتے ہیں، رگیں کالی پڑ جاتی ہیں اور پتے جھڑ جاتے ہیں۔",
            "treatment": "کاپر آکسی کلورائیڈ 500 گرام + اسٹریپٹو مائیسن 50 گرام فی 100 لیٹر پانی میں ملا کر فی ایکڑ اسپرے کریں۔"
          }
        ]
      }
    },
    "Sesame": {
      "en": {
        "kasht": "• Land Preparation: Fine tilth is essential. Plow 3 times and perform heavy rolling to keep moisture locked in.\n"
                 "• Ideal Planting Schedule: June 15 to July 15. Sowing outside this dynamic framework results in poor vegetative rooting.\n"
                 "• Varieties: TH-6, TS-5, and Black Sesame variants. Sourcing must be disease-indexed from certified research labs.\n"
                 "• Seed Rate Matrix: Use exactly 1.5 to 2 kg of clean seed mixed with dry sand to ensure even distribution during broadcasting.\n"
                 "• Method: Sowing on 2.5 feet beds via cotton planter provides unparalleled defense against accidental monsoon drowning.\n"
                 "• Ensure plant-to-plant isolation spacing of 4 to 6 inches during the thinning phase done 15 days post-emergence.",
        "pani": "• Sesame requires very low water volumes but is hyper-sensitive to irrigation balance:\n"
                 "• Critical Rule: Never allow water to stand in a sesame field for more than 4 hours; it chokes oxygen lines completely.\n"
                 "• Standard Schedule: Apply 1st irrigation 21 days after sowing. 2nd at capsule initiation, and 3rd during grain filling stage.\n"
                 "• If monsoon rains match growth cycles, drop structural irrigation to avoid root damping-off diseases.",
        "khaad": "• Nutrient Framework: Avoid high nitrogen inputs to prevent lodging.\n"
                 "• At Sowing: Apply 1 bag of DAP and half a bag of SOP per acre. Do not apply nitrogenous fertilizer early on.\n"
                 "• At Flowering Stage: Apply half a bag of Urea to support long capsule development and enhance oil percentage extraction.",
        "spray": "• Weed management is vital because sesame grows slowly during its first 20 days:\n"
                 "• Pre-emergence Rule: Spray S-Metolachlor @ 800 ml per acre within 24 hours of planting to suppress wild weeds.\n"
                 "• Post-emergence Capsule Protection: Spray Bifenthrin @ 250 ml to eliminate the damaging Sesame Capsule Borer insects.",
        "bimariyan": [
          {
            "name": "Phyllody Disease",
            "symptoms": "Floral components turn into irregular green leaves, preventing any pod/seed creation. Deforms the entire crop head.",
            "treatment": "Transmitted by Leafhoppers. Spray Acetamiprid @ 150 grams per acre immediately upon sighting vector insects."
          }
        ]
      },
      "ur": {
        "kasht": "• XML زمین کی تیاری: مٹی کا نرم ہونا ضروری ہے۔ 3 بار ہل چلا کر بھاری سہاگا دیں تاکہ زمین کی نمی برقرار رہے۔\n"
                 "• بہترین وقتِ کاشت: 15 جون سے 15 جولائی تک ہے۔ اس وقت کے آگے پیچھے کاشت کرنے سے جڑیں کمزور بنتی ہیں۔\n"
                 "• منظور شدہ اقسام: ٹی ایچ-6، ٹی ایس-5 اور سیاہ تل کی اقسام کا تصدیق شدہ بیج استعمال کریں۔\n"
                 "• شرح بیج: چھٹا دینے کے لیے ٹھیک 1.5 سے 2 کلوگرام صاف بیج کو خشک ریت میں ملا کر استعمال کریں تاکہ یکساں پھیلاؤ ہو۔\n"
                 "• طریقہ کاشت: کپاس والے پلانٹر کی مدد سے 2.5 فٹ کی کھیلوں پر کاشت کریں تاکہ بارش کا فالتو پانی فصل کو ڈبو نہ سکے۔\n"
                 "• چھدرائی (Thinning): اگاؤ کے 15 دن بعد پودوں کا درمیانی فاصلہ 4 سے 6 انچ برقرار رکھنے کے لیے فالتو پودے نکال دیں۔",
        "pani": "• تل کو بہت کم پانی کی ضرورت ہوتی ہے لیکن یہ پانی کے توازن کے لیے انتہائی حساس ہے:\n"
                 "• اہم ترین اصول: کھیت میں پانی 4 گھنٹے سے زیادہ کھڑا نہ رہنے دیں، ورنہ پودے کا دم گھٹ جائے گا اور جڑیں گل جائیں گی۔\n"
                 "• آبپاشی کا شیڈول: پہلا پانی بوائی کے 21 دن بعد، دوسرا پانی پھلیاں بنتے وقت اور تیسرا پانی دانہ بنتے وقت دیں۔\n"
                 "• اگر مانسون کی بارشیں ہو رہی ہوں تو مصنوعی پانی بند کر دیں تاکہ جڑوں کے سوکھنے کی بیماری (Damping-off) نہ آئے۔",
        "khaad": "• کھاد کا پلان: تل کو زیادہ نائٹروجن (یوریا) مت دیں ورنہ فصل قد کر کے گر جائے گی۔\n"
                 "• بوائی کے وقت: 1 بوری ڈی اے پی اور آدھی بوری ایس او پی (پوٹاش) فی ایکڑ دیں۔ شروع میں یوریا کھاد ہرگز نہ دیں۔\n"
                 "• پھول آنے پر: پھلیوں کی لمبائی اور دانے میں تیل کی مقدار بڑھانے کے لیے صرف آدھی بوری یوریا کھاد دیں۔",
        "spray": "• جڑی بوٹیوں کا تدارک ضروری ہے کیونکہ شروع کے 20 دن تل کا پودا بہت آہستہ بڑھتا ہے:\n"
                 "• اگاؤ سے پہلے: بوائی کے 24 گھنٹے کے اندر ایس-میٹولاکلور بحساب 800 ملی لیٹر فی ایکڑ اسپرے کریں تاکہ جڑی بوٹیاں نہ اگیں۔\n"
                 "• پھلیاں بنتے وقت: تل کی پھلی کی سنڈی کے خاتمے کے لیے بائی فینتھرین 250 ملی لیٹر فی ایکڑ اسپرے کریں۔",
        "bimariyan": [
          {
            "name": "پتہ نما سٹہ (Phyllody)",
            "symptoms": "پھولوں کی جگہ بدشکل سبز پتے نکل آتے ہیں، جس سے پھلی اور بیج نہیں بنتے اور پورا پودا جھاڑی بن جاتا ہے۔",
            "treatment": "یہ بیماری چست تیلے (Leafhopper) سے پھیلتی ہے۔ اس کے نظر آتے ہی ایسیٹامیپرڈ 150 گرام فی ایکڑ اسپرے کریں۔"
          }
        ]
      }
    },
    "Maize": {
      "en": {
        "kasht": "• Sowing Windows: Spring Maize (Jan 15 to Feb 28); Autumn Maize (July 1 to Aug 15). Strict adherence saves the crop from pollination failure.\n"
                 "• Hybrids Matrix: Pioneer 30Y87, Y84, Monsanto DK-6789. Never use F2 generational saved seeds.\n"
                 "• Seeding Density: Use 8 to 10 kg of premium graded seed per acre to hit targeted growth limits.\n"
                 "• Precision Geometry: Ridges must be spaced 2.5 feet apart, with single seeds placed at 6 to 7-inch intervals on the ridge side.",
        "pani": "• Maize is a high-water-consumption crop, needing 10-12 irrigations based on direct solar evaporation indices.\n"
                 "• Critical Peak: Flowering (Tasseling) and Silking phases cannot handle even 12 hours of dry soil delay.\n"
                 "• Hot Climate Care: During June/August, irrigate every 5 to 7 days to maintain internal transpiration balancing.",
        "khaad": "• Heavy Nutrient Demands: Sowing requires 2 bags DAP + 1 bag SOP + 10 kg Zinc Sulphate (21%).\n"
                 "• Urea Splitting Rule: Apply 3 bags of Urea in 4 split doses: at 4-leaf stage, 8-leaf stage, knee-height stage, and pre-tasseling.",
        "spray": "• Pre-emergence: Spray Atrazine + S-Metolachlor within 24 hours of sowing to stop broad and narrow leaves.\n"
                 "• Fall Armyworm (FAW): Spray Emamectin Benzoate + Lufenuron or Chlorantraniliprole into the whorl if damage reaches 5%.",
        "bimariyan": [
          {
            "name": "Shoot Fly (Atherigona soccata)",
            "symptoms": "Attacks young seedlings; central leaf dries out completely, forming a 'dead heart' that pulls out easily.",
            "treatment": "Apply Carbofuran 3G granules @ 4 kg per acre inside the furrows during the 2nd leaf growth stage."
          }
        ]
      },
      "ur": {
        "kasht": "• وقتِ کاشت: بہاریہ مکئی (15 جنوری سے 28 فروری)؛ خریف مکئی (1 جولائی سے 15 اگست)۔ وقت کی پابندی شدید گرمی میں پولینیشن بچاتی ہے۔\n"
                 "• ہائبرڈ اقسام: پائینیر 30Y87، Y84، اور مونسینٹو DK-6789 کا انتخاب کریں۔ گھر کا رکھا ہوا بیج دوبارہ ہرگز کاشت نہ کریں۔\n"
                 "• شرح بیج: فی ایکڑ بہترین پودوں کی تعداد کے لیے 8 سے 10 کلوگرام گریڈڈ ہائبرڈ بیج استعمال کریں۔\n"
                 "• طریقہ کاشت: کھیلیاں 2.5 فٹ کے فاصلے پر بنائیں اور بیج کھیلوں کی ایک سائیڈ پر 6 سے 7 انچ کے فاصلے پر چوپے سے لگائیں۔",
        "pani": "• مکئی پانی زیادہ استعمال کرنے والی فصل ہے، اسے موسمی حالات کے مطابق 10 سے 12 پانیوں کی ضرورت ہوتی ہے۔\n"
                 "• نازک ترین مرحلہ: بور نکلتے وقت (Tasseling) اور چھلی بنتے وقت (Silking) اگر 12 گھنٹے کا भी سوکا لگا تو پیداوار آدھی رہ جائے گی۔\n"
                 "• گرمی کا شیڈول: جون اور اگست کی شدید گرمی میں ہر 5 سے 7 دن بعد پانی لازمی لگائیں تاکہ پودا نہ جھلسے۔",
        "khaad": "• کھاد کی بھاری ضرورت: بوائی کے وقت 2 بوری ڈی اے پی + 1 بوری ایس او پی (پوٹاش) + 10 کلو زنک سلفیٹ (21 فیصد) لازمی دیں۔\n"
                 "• یوریا کھاد کی تقسیم: کل 3 بوری یوریا کو 4 قسطوں میں دیں: 4 پتوں پر، 8 پتوں پر، گھٹنے کے قد پر، اور چھلی بننے سے پہلے۔",
        "spray": "• اگاؤ سے پہلے: بوائی کے 24 گھنٹے کے اندر ایٹرازین + ایس-میٹولاکلور کا اسپرے کریں تاکہ نوکیلے اور چوڑے پتے والی جڑی بوٹیاں نہ اگیں۔\n"
                 "• لشکری سنڈی (Fall Armyworm): نقصان 5 فیصد ہوتے ہی کونپل کے اندر ایما مکیٹن بینزوایٹ + لوفینوران یا کلورینٹرانیلی پرول کا اسپرے کریں۔",
        "bimariyan": [
          {
            "name": "کونپل کی مکھی (Shoot Fly)",
            "symptoms": "چھوٹے پودوں پر حملہ کرتی ہے؛ درمیانی پتہ مکمل سوکھ جاتا ہے جسے 'Dead Heart' کہتے ہیں اور پودا وہیں رک جاتا ہے۔",
            "treatment": "بوائی کے وقت یا دوسرے پتے کے مرحلے پر کاربوفیوران 3G دانے دار کھاد بحساب 4 کلوگرام فی ایکڑ کھیلوں میں ڈال۔۔"
          }
        ]
      }
    },
    "Rice": {
      "en": {
        "kasht": "• Nursery Sowing Timeline: May 20 to June 20. Transplanting must happen within 25 to 30 days of nursery growth.\n"
                 "• Premium Varieties: Basmati 515, Super Basmati, PK 1121, and Kainat variants.\n"
                 "• Seeding Rate Matrix: 4-5 kg for fine Basmati variants per acre nursery layout setup.\n"
                 "• Puddling Phase (Kaddu): Perform aggressive dry plowing, fill with water, and puddling 3 times to destroy bottom percolation zones.",
        "pani": "• Standing Water Rule: Keep exactly 2 to 3 inches of standing water uniform for the first 25 days post-transplantation.\n"
                 "• Drying Cycles: After 30 days, implement alternate wetting and drying to encourage core aerobic rooting zones.\n"
                 "• Harvest Cutoff: Drain fields completely exactly 15 days before structural harvest to allow grain alignment.",
        "khaad": "• Nutrition Layout: Apply 1 bag DAP + 1 bag SOP during the final puddling stage before alignment.\n"
                 "• Nitrogen Application: Apply 1.5 bags of Ammonium Sulphate or 1 bag Urea at day 15, and repeat at day 30.\n"
                 "• Zinc Check: Apply 5 kg of Zinc Sulphate (33% or 21% alternative) at day 20 to prevent the highly destructive 'Khaira' disease.",
        "spray": "• Weed Elimination: Apply Butachlor 60% EC @ 800 ml or Pretilachlor within 3-5 days of transplantation into standing water.\n"
                 "• Stem Borer Control: Apply Cartap Hydrochloride 4G granules @ 9 kg per acre at day 40 to eradicate stem tunneling pests.",
        "bimariyan": [
          {
            "name": "Rice Blast Fungal Attack",
            "symptoms": "Spindle-shaped lesion spots with bluish-grey centers develop on leaves, choking photosynthetic production completely.",
            "treatment": "Spray Tricyclazole 75 WP @ 120 grams or Nativo @ 65 grams per acre mixed in 120 Liters of fresh water."
          }
        ]
      },
      "ur": {
        "kasht": "• پنیری کی کاشت: 20 مئی سے 20 جون تک کریں۔ پنیری جب 25 سے 30 دن کی ہو جائے تو کھیت میں منتقل کر دیں۔\n"
                 "• منظور شدہ اقسام: باسمتی 515، سپر باسمتی، پی کے 1121، اور کائنات اقسام کا خالص بیج لیں۔\n"
                 "• شرح بیج: فائن باسمتی اقسام کے لیے 4 سے 5 کلوگرام بیج فی ایکڑ کی پنیری کے لیے کافی ہے۔\n"
                 "• کدو کرنے کا طریقہ (Puddling): پہلے خشک ہل چلائیں، پھر پانی بھر کر 3 بار کدو کریں تاکہ زمین کی نچلی سطح سخت ہو اور پانی نہ رسے۔",
        "pani": "• کھڑے پانی کا اصول: پنیری منتقل کرنے کے پہلے 25 دن تک کھیت میں 2 سے 3 انچ پانی ہر وقت کھڑا رہنا لازمی ہے۔\n"
                 "• پانی بدلنے کا عمل: 30 دن کے بعد کھیت کو متبادل طور پر سکھائیں اور پانی دیں تاکہ جڑوں کو آکسیجن مل سکے۔\n"
                 "• پانی کی بندش: فصل کی کٹائی سے ٹھیک 15 دن پہلے پانی مکمل بند کر دیں تاکہ مٹی سخت ہو جائے اور کٹائی میں آسانی ہو۔",
        "khaad": "• کھاد کا استعمال: آخری کدو کے وقت یعنی پودے لگانے سے پہلے 1 بوری ڈی اے پی + 1 بوری ایس او پی فی ایکڑ ڈالیں۔\n"
                 "• نائٹروجن پلان: پودے لگانے کے 15 دن بعد 1 بوری امونیم سلفیٹ اور 30 دن بعد 1 بوری یوریا کھاد دیں۔\n"
                 "• زنک کی کمی (حد سے زیادہ اہم): منتقلی کے 20 دن بعد 5 کلو زنک سلفیٹ (33 فیصد) لازمی دیں تاکہ 'کھیرو' بیماری نہ آئے۔",
        "spray": "• جڑی بوٹی مار اسپرے: منتقلی کے 3 سے 5 دن کے اندر اندر کھڑے پانی میں بیوٹا کلور 60٪ EC بحساب 800 ملی لیٹر کا چھٹا کریں۔\n"
                 "• تنے کی سنڈی (Stem Borer): منتقلی کے 40 دن بعد کارٹاپ ہائیڈروکلورائیڈ 4G دانے دار کھاد 9 کلوگرام فی ایکڑ فلڈ کریں۔",
        "bimariyan": [
          {
            "name": "دھان کا جھلساؤ (Rice Blast)",
            "symptoms": "پتوں پر درمیان سے چوڑے اور کناروں سے تیکھے (تکلا نما) بھورے دھبے بنتے ہیں جن کے درمیان کا حصہ سرمئی ہوتا ہے۔",
            "treatment": "ٹرائی سائیکلازول 75 WP بحساب 120 گرام یا نیٹیوو 65 گرام فی ایکڑ 120 لیٹر پانی میں ملا کر اسپرے کریں۔"
          }
        ]
      }
    },
    "Sugarcane": {
      "en": {
        "kasht": "• Planting Systems: Autumn Sowing (Sep 1 to Oct 15); Spring Sowing (Feb 15 to March 27). Autumn gives 25% extra structural volume.\n"
                 "• High-Recovery Varieties: CPF-249, CPF-253, and HSF-240. Avoid local unapproved diseased selections.\n"
                 "• Seed Rate Matrix: Use 40,000 to 50,000 double-budded cane sets (approx 100-120 maunds) per acre.\n"
                 "• Planting Design: Deep trenches must be carved 4 feet apart using a double-row ridger tool to prevent mature crop weight bending.",
        "pani": "• Extensive Lifespan Irrigation: Requires 16 to 22 irrigations spread across its entire 12-month vegetative timeline.\n"
                 "• Summer Routine: Water every 8-10 days during May-July peak dry wind scenarios to prevent internal sugar reduction.\n"
                 "• Lodging Control: Earthing up lines must be done before July monsoons to reinforce root soil holds against winds.",
        "khaad": "• Baseline Inputs: Apply 2.5 bags DAP + 1.5 bags SOP during trench preparation phases.\n"
                 "• Nitrogen Framework: Requires 4 bags of Urea per acre, split uniformly across irrigation phases up until mid-July cutoff limits.",
        "spray": "• Early Weed Suppression: Spray Metribuzin @ 500 grams per acre within 48 hours of set placement to ensure complete soil clean coverage.\n"
                 "• Black Bug Control: Spray Chlorpyrifos @ 1 Liter with early water channels if bugs appear near lower node junctions.",
        "bimariyan": [
          {
            "name": "Red Rot Fungal Devastation",
            "symptoms": "Third or fourth leaves turn yellow and dry up; splitting the cane lengthwise reveals blood-red tissues with sour alcoholic smell.",
            "treatment": "No internal chemical cure. Immediately dig out infected clumps and burn them. Use healthy seeds next cycle."
          }
        ]
      },
      "ur": {
        "kasht": "• وقتِ کاشت: ستمبر کاشتہ (1 ستمبر سے 15 اکتوبر)؛ بہاریہ کاشتہ (15 فروری سے 27 مارچ)۔ ستمبر کی کاشت 25 فیصد زیادہ پیداوار دیتی ہے۔\n"
                 "• زیادہ ریکوری والی اقسام: سی پی ایف-249، سی پی ایف-253، اور ایچ ایس ایف-240 کا بیج استعمال کریں۔\n"
                 "• شرح بیج: فی ایکڑ 40,000 سے 50,000 دو اکھیا سمے (تقریباً 100 سے 120 من بیج) استعمال کریں۔\n"
                 "• طریقہ کاشت: ڈبل رو رِجر کی مدد سے 4 فٹ کے فاصلے پر گہری کھالیاں بنائیں تاکہ فصل بھاری ہو کر گر نہ سکے۔",
        "pani": "• طویل مدتی آبپاشی: کماد بارہ مہینے کی فصل ہے، اسے پورے سال میں 16 سے 22 پانیوں کی ضرورت ہوتی ہے۔\n"
                 "• گرمیوں کا شیڈول: مئی سے جولائی کے گرم مہینوں میں ہر 8 سے 10 دن بعد پانی لازمی دیں تاکہ گنے کا رس نہ سوکھے۔\n"
                 "• مٹی چڑھانا (Earthing up): جولائی کی بارشوں اور تیز ہواؤں سے پہلے گنے کی لائنوں پر مٹی چڑھائیں تاکہ فصل گرنے سے بچ سکے۔",
        "khaad": "• بنیادی کھادیں: کھالیاں بناتے وقت 2.5 بوری ڈی اے پی + 1.5 بوری ایس او پی (پوٹاش) فی ایکڑ ڈالیں۔\n"
                 "• یوریا کا استعمال: فصل کو کل 4 بوری یوریا کھاد کی ضرورت ہوتی ہے، جسے جولائی کے وسط تک مختلف اقساط میں پورا کریں۔",
        "spray": "• جڑی بوٹیوں کا خاتمہ: سمے دبانے کے بعد 48 گھنٹے کے اندر میٹری بیوزن 500 گرام فی ایکڑ اسپرے کریں تاکہ جڑی بوٹیاں صاف ہو جائیں۔\n"
                 "• کالا بگ (Black Bug): گنے کے نچلے پوروں پر کالے رنگ کے کیڑے نظر آنے پر کلورپائریفوس 1 لیٹر فی ایکڑ پانی کے ساتھ فلڈ کریں۔",
        "bimariyan": [
          {
            "name": "گنے کا رتہ روگ (Red Rot)",
            "symptoms": "اوپر سے تیسرا چوتھا پتہ پیلا ہو کر سوکھنے لگتا ہے؛ گنے کو لمبائی میں پھاڑیں تو اندر سے گوشت کی طرح سرخ نکلتا ہے اور کھٹی بو آتی ہے۔",
            "treatment": "کھیت میں اس کا کوئی علاج نہیں ہے۔ متاثرہ گنے جڑ سے اکھاڑ کر جلا دیں اور اگلی بار صحت مند بیج کا انتخاب کریں۔"
          }
        ]
      }
    }
  };

  @override
  void initState() {
    super.initState();
    _wf = WeatherFactory(_apiKey);
    _tabController = TabController(length: 5, vsync: this);
    _fetchWeather();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchWeather() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Weather weather = await _wf.currentWeatherByCityName(AppConfig.defaultWeatherCity);
      setState(() {
        _currentWeather = weather;
        _isLoadingWeather = false;
        _isOffline = false;
      });
      if (weather.toJson() != null) {
        await prefs.setString('cached_weather', jsonEncode(weather.toJson()));
      }
    } catch (e) {
      debugPrint("Weather Offline Cache Handling: $e");
      final String? cachedData = prefs.getString('cached_weather');
      if (cachedData != null) {
        setState(() {
          _currentWeather = Weather(jsonDecode(cachedData));
          _isLoadingWeather = false;
          _isOffline = true;
        });
      } else {
        setState(() {
          _isLoadingWeather = false;
          _isOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentCropName = _crops[_selectedCropIndex]['name'];
    String langCode = widget.isUrdu ? "ur" : "en";
    var currentDetails = _cropDetailsData[currentCropName]?[langCode] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Premium Green & Yellow Adaptive Weather Capsule
            _buildLiveWeatherHeader(),
            const SizedBox(height: 15),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: widget.isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isUrdu ? "فصل کی قسم منتخب کریں" : "Select Crop Type", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkGrey)
                  ),
                  const SizedBox(height: 10),
                  _buildCropGrid(),
                  const SizedBox(height: 18),
                  
                  Row(
                    mainAxisAlignment: widget.isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
                    textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      const Icon(Icons.analytics, color: primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.isUrdu 
                              ? "جامع تکنیکی معلومات: ${_crops[_selectedCropIndex]['urdu']}"
                              : "Advanced Agronomy: $currentCropName Guide",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Premium Custom Custom TabBar Styling with TextDirection Control
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black12),
              ),
              child: Directionality(
                textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: accentYellow,
                  indicatorWeight: 3.5,
                  labelColor: primaryGreen,
                  unselectedLabelColor: Colors.black45,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: widget.isUrdu ? 15 : 13,
                    fontFamily: widget.isUrdu ? 'Urdu' : null
                  ),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.wb_twilight, size: 18),
                      text: widget.isUrdu ? "کاشت" : "Sowing",
                    ),
                    Tab(
                      icon: const Icon(Icons.water_drop, size: 18),
                      text: widget.isUrdu ? "پانی" : "Irrigation",
                    ),
                    Tab(
                      icon: const Icon(Icons.compost, size: 18),
                      text: widget.isUrdu ? "کھاد" : "Fertilizer",
                    ),
                    Tab(
                      icon: const Icon(Icons.clean_hands, size: 18),
                      text: widget.isUrdu ? "اسپرے" : "Spray",
                    ),
                    Tab(
                      icon: const Icon(Icons.coronavirus, size: 18),
                      text: widget.isUrdu ? "بیماریاں" : "Diseases",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Main Detailed Content Output Window
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildTextTabContent(currentDetails['kasht'] ?? ""),
                        _buildTextTabContent(currentDetails['pani'] ?? ""),
                        _buildTextTabContent(currentDetails['khaad'] ?? ""),
                        _buildTextTabContent(currentDetails['spray'] ?? ""),
                        _buildDiseasesTabContent(currentDetails['bimariyan'] ?? []),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveWeatherHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryGreen, Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accentYellow, width: 1.5), // Yellow Frame Accenting
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingWeather
          ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: accentYellow)))
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Column(
                  crossAxisAlignment: widget.isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Text(widget.isUrdu ? "لّیہ، مانیٹرنگ باکس" : "Layyah Live Feed",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_isOffline) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.cloud_off, color: accentYellow, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isOffline 
                          ? (widget.isUrdu ? "محفوظ شدہ آف لائن معلومات" : "OFFLINE CACHED REC") 
                          : (_currentWeather?.weatherDescription?.toUpperCase() ?? "STABLE"),
                      style: const TextStyle(color: accentYellow, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(Icons.air, color: Colors.white70, size: 14),
                        Text(widget.isUrdu 
                            ? " ہوا کی رفتار: ${_currentWeather?.windSpeed?.toStringAsFixed(1)} میٹر/سک"
                            : " Wind Velocity: ${_currentWeather?.windSpeed?.toStringAsFixed(1)} m/s", 
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    )
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentWeather?.temperature?.celsius != null 
                          ? "${_currentWeather!.temperature!.celsius!.toStringAsFixed(0)}°C" 
                          : "--°C",
                      style: const TextStyle(color: accentYellow, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.isUrdu ? "لائیو درجہ حرارت" : "Live Temp",
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    )
                  ],
                )
              ],
            ),
    );
  }

  Widget _buildCropGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.15,
      ),
      itemCount: _crops.length,
      itemBuilder: (context, index) {
        bool isSelected = _selectedCropIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedCropIndex = index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? lightYellow : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? accentYellow : Colors.black12, width: isSelected ? 2 : 1),
              boxShadow: isSelected ? [BoxShadow(color: accentYellow.withOpacity(0.2), blurRadius: 4)] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_crops[index]['icon'], color: isSelected ? primaryGreen : Colors.grey.shade600, size: 24),
                const SizedBox(height: 4),
                Text(
                  widget.isUrdu ? _crops[index]['urdu'] : _crops[index]['name'], 
                  style: TextStyle(
                    color: isSelected ? primaryGreen : darkGrey, 
                    fontWeight: FontWeight.bold, 
                    fontSize: widget.isUrdu ? 15 : 12,
                    fontFamily: widget.isUrdu ? 'Urdu' : null
                  )
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextTabContent(String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Text(
        content,
        textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
        textAlign: widget.isUrdu ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: widget.isUrdu ? 15 : 14, 
          height: 1.7, 
          color: darkGrey, 
          fontWeight: FontWeight.w500,
          fontFamily: widget.isUrdu ? 'Urdu' : null
        ),
      ),
    );
  }

  Widget _buildDiseasesTabContent(List<dynamic> diseases) {
    if (diseases.isEmpty) {
      return Center(
        child: Text(
          widget.isUrdu ? "اس فصل کی بیماریوں کا تفصیلی ڈیٹا جلد شامل کیا جائے گا۔" : "Advanced disease logs will be available soon.",
          textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black38),
        )
      );
    }

    return ListView.builder(
      itemCount: diseases.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      itemBuilder: (context, index) {
        var disease = diseases[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black12),
          ),
          child: Directionality(
            textDirection: widget.isUrdu ? TextDirection.rtl : TextDirection.ltr,
            child: ExpansionTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              title: Text(
                disease['name'] ?? 'Infection',
                textAlign: widget.isUrdu ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14, 
                  color: primaryGreen,
                  fontFamily: widget.isUrdu ? 'Urdu' : null
                ),
              ),
              iconColor: accentYellow,
              collapsedIconColor: Colors.black45,
              childrenPadding: const EdgeInsets.all(14),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.black12),
                const SizedBox(height: 2),
                Text(
                  widget.isUrdu ? "فیلڈ علامات (Field Identification):" : "Field Symptoms:",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  disease['symptoms'] ?? '',
                  textAlign: widget.isUrdu ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(fontSize: 13, color: darkGrey, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isUrdu ? "کیمیائی و حیاتیاتی تدارک (Chemical Treatment):" : "Recommended Treatment:",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  disease['treatment'] ?? '',
                  textAlign: widget.isUrdu ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(fontSize: 13, color: darkGrey, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}