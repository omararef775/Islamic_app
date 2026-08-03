
Sign in
Help

quran_library 4.2.1 copy "quran_library: ^4.2.1" to clipboard
Published 30 days ago • verified publisheralheekmahlib.com
SDKFlutterPlatformAndroidiOSLinuxmacOSwebWindows
liked status: inactive
83
Readme
Changelog
Example
Installing
Versions
Scores
Quran Library 


pub package pub points likes Pub Downloads License: MIT

Web Windows macOS Android iOS

Choose your language for the documentation:

Arabic English bangla Bahasa Indonesia Urdu Türkçe Kurdish Bahasa Malaysia Español

Important note before starting to use: Please make: 
  useMaterial3: false,
In order not to cause any formation problems 
Table of Contents 
Getting started
Usage Example
Basic Quran Screen
Individual Surah Display
Single Ayah Display
Partial Pages (single or range) + Highlighting
Utils
Getting all Quran's Jozzs, Hizbs, and Surahs
to jump between pages, Surahs or Hizbs you can use
Adding, setting, removing, getting and navigating to bookmarks
searching for any Ayah
Fonts Download
Word Audio (Word-by-Word)
Tafsir
Audio Playback
Sources
License
Getting started 
Android
The required permissions for audio playback (WAKE_LOCK, and FOREGROUND_SERVICE_MEDIA_PLAYBACK) are automatically added by the package. You don't need to manually edit your AndroidManifest.xml.

Additionally, to enable system-integrated audio controls (notification/lockscreen) using audio_service, your app's MainActivity must extend AudioServiceActivity:

Kotlin:

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity()
Java:

import com.ryanheise.audioservice.AudioServiceActivity;

public class MainActivity extends AudioServiceActivity {}
If you don't apply this change, the audio will still work locally, but AudioService.init() may fail and system controls won't be available.

iOS
For background audio playback, you must add the following to your app's Info.plist:

<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
This allows audio playback to continue when the app is in the background.

In the pubspec.yaml of your flutter project, add the following dependency:

dependencies:
  ...
  quran_library: ^4.2.1
Import it:

import 'package:quran_library/quran_library.dart';
Initialize it:

Future<void> main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await QuranLibrary.init();
  runApp(
    const MyApp(),
  );
}
Usage Example 
Basic Quran Screen 
/// You can just add it to your code like this:
class MyQuranPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      parentContext: context, // Required 
    );
  }
}
or give it some options:
QuranLibraryScreen(
            parentContext: context,
            withPageView: true,
            useDefaultAppBar: true,
            isShowAudioSlider: true,
            showAyahBookmarkedIcon: false,
            isDark: isDark,
            appLanguageCode: Get.locale!.languageCode,
            backgroundColor: context.theme.colorScheme.surface,
            textColor: context.textDarkColor,
            ayahSelectedBackgroundColor:
                context.theme.colorScheme.primary.withValues(alpha: .2),
            ayahIconColor: context.theme.colorScheme.primary,
            surahInfoStyle:
                SurahInfoStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              ayahCount: 'aya_count'.tr,
              firstTabText: 'surahNames'.tr,
              secondTabText: 'aboutSurah'.tr,
              bottomSheetWidth: 500,
            ),
            basmalaStyle: BasmalaStyle(
              verticalPadding: 0.0,
              basmalaColor: context.textDarkColor.withValues(alpha: .8),
              basmalaFontSize: isLoadedFont ? 120.0 : 25.0,
            ),
            ayahStyle: AyahAudioStyle.defaults(isDark: isDark, context: context)
                .copyWith(
              dialogWidth: 300,
              readersTabText: 'readers'.tr,
            ),
            topBarStyle:
                QuranTopBarStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              showAudioButton: false,
              showFontsButton: false,
              tabIndexLabel: 'index'.tr,
              tabBookmarksLabel: 'bookmarks'.tr,
              tabSearchLabel: 'search'.tr,
            ),
            indexTabStyle:
                IndexTabStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              tabSurahsLabel: 'surahs'.tr,
              tabJozzLabel: 'juzz'.tr,
            ),
            searchTabStyle:
                SearchTabStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              searchHintText: 'search'.tr,
            ),
            bookmarksTabStyle:
                BookmarksTabStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              emptyStateText: 'no_bookmarks_yet'.tr,
              greenGroupText: 'greenBookmarks'.tr,
              yellowGroupText: 'yellowBookmarks'.tr,
              redGroupText: 'redBookmarks'.tr,
            ),
            ayahMenuStyle:
                AyahMenuStyle.defaults(isDark: isDark, context: context)
                    .copyWith(
              copySuccessMessage: 'ayah_copied'.tr,
              showPlayAllButton: false,
            ),
            tafsirStyle:
                TafsirStyle.defaults(isDark: isDark, context: context).copyWith(
              widthOfBottomSheet: 500,
              heightOfBottomSheet: MediaQuery.sizeOf(context).height * 0.9,
              changeTafsirDialogHeight: MediaQuery.sizeOf(context).height * 0.9,
              changeTafsirDialogWidth: 400,
              tafsirNameWidget: customSvgWithCustomColor(
                'assets/svg/tafseer_white.svg',
                color: context.theme.colorScheme.primary,
                height: 24,
              ),
              tafsirName: 'tafsir'.tr,
              translateName: 'translate'.tr,
              tafsirIsEmptyNote: 'tafsirIsEmptyNote'.tr,
              footnotesName: 'footnotes'.tr,
            ),
            topBottomQuranStyle: TopBottomQuranStyle.defaults(
              isDark: isDark,
              context: context,
            ).copyWith(
              hizbName: 'hizb'.tr,
              juzName: 'juz'.tr,
              sajdaName: 'sajda'.tr,
            ),
          ),
Individual Surah Display 
Expand section
Single Ayah Display 
Expand section
Partial Pages (single or range) + Highlighting 
Expand section
Using GetSingleAyah in a list:
Expand section
Utils 
The package provides a lot of utils like: 
Getting all Quran's Jozzs, Hizbs, and Surahs 
final jozzs = QuranLibrary.allJoz;
final hizbs = QuranLibrary.allHizb;
final surahs = QuranLibrary.getAllSurahs();
final ayahsOnPage = QuranLibrary().getAyahsByPage();

/// [getSurahInfo] let's you get a Surah with all its data when you pass Surah number
final surah = QuranLibrary().getSurahInfo(1);
to jump between pages, Surahs or Hizbs you can use: 
/// [jumpToAyah] let's you navigate to any ayah..
/// It's better to call this method while Quran screen is displayed
/// and if it's called and the Quran screen is not displayed, the next time you
/// open quran screen it will start from this ayah's page
QuranLibrary().jumpToAyah(AyahModel ayah);
/// or you can use:
/// jumpToPage, jumpToJoz, jumpToHizb, jumpToBookmark and jumpToSurah.

Adding, setting, removing, getting and navigating to bookmarks: 
// In init function
QuranLibrary().init(userBookmarks: [Bookmark(id: 0, colorCode: Colors.red.value, name: "Red Bookmark")]);
final usedBookmarks = QuranLibrary().getUsedBookmarks();
QuranLibrary().setBookmark(surahName: 'Al-Fatihah', ayahNumber: 5, ayahId: 5, page: 1, bookmarkId: 0);
QuranLibrary().removeBookmark(bookmarkId: 0);
QuranLibrary().jumpToBookmark(BookmarkModel bookmark);
 

searching for any Ayah 
TextField(
  onChanged: (txt) {
    final _ayahs = QuranLibrary().search(txt);
      setState(() {
        ayahs = [..._ayahs];
      });
  },
  decoration: InputDecoration(
    border:  OutlineInputBorder(borderSide: BorderSide(color: Colors.black),),
    hintText: 'Search',
  ),
),

Word Info (Recitations / Tasreef / Eerab) 
/// Open Word Info bottom sheet (with on-demand download)
await QuranLibrary().showWordInfoByNumbers(
  context: context,
  surahNumber: 1,
  ayahNumber: 1,
  wordNumber: 1,
  initialKind: WordInfoKind.recitations,
  isDark: true,
);

/// (Optional) download a specific kind programmatically
if (!QuranLibrary().isWordInfoKindDownloaded(WordInfoKind.recitations)) {
  await QuranLibrary().downloadWordInfoKind(kind: WordInfoKind.recitations);
}
Word Audio (Word-by-Word) 
Enable word audio playback to hear individual words or all words of an ayah sequentially. 
// Initialize word audio (call once after QuranLibrary.init())
QuranLibrary.initWordAudio();
Play a Single Word 
// Play word audio using WordRef
await QuranLibrary().playWordAudio(
  ref: const WordRef(surahNumber: 1, ayahNumber: 1, wordNumber: 1),
);

// Or using numbers directly
await QuranLibrary().playWordAudioByNumbers(
  surahNumber: 1,
  ayahNumber: 1,
  wordNumber: 1,
);
Play All Words of an Ayah 
// Play all words of an ayah sequentially
await QuranLibrary().playAyahWordsAudioByNumbers(
  surahNumber: 1,
  ayahNumber: 1,
);
Stop & State 
// Stop playback
await QuranLibrary().stopWordAudio();

// Check state
bool isPlaying = QuranLibrary().isWordAudioPlaying;
bool isLoading = QuranLibrary().isWordAudioLoading;
bool isAyahMode = QuranLibrary().isPlayingAyahWords;
int wordCount = QuranLibrary().getAyahWordCount(surahNumber: 1, ayahNumber: 1);
Note: Audio buttons also appear automatically inside the Word Info bottom sheet when word audio is initialized.

Fonts Download 
To download Quran fonts, you have two options: 
As for using the default dialog, you can modify the style in it. 
Or you can create your own design using all the functions for downloading fonts. 
macOS needs you to request a specific entitlement in order to access the network. 
To do that: open macos/Runner/DebugProfile.entitlements and add the following key-value pair. 
<key>com.apple.security.network.client</key>
<true/>
///
/// to get the fonts download dialog just call [getFontsDownloadDialog]
///
/// and pass the language code to translate the number if you want,
/// the default language code is 'ar' [languageCode]
/// and style [DownloadFontsDialogStyle] is optional.
QuranLibrary().getFontsDownloadDialog(downloadFontsDialogStyle, languageCode);

/// to get the fonts download widget just call [getFontsDownloadWidget]
Widget getFontsDownloadWidget(context, {downloadFontsDialogStyle, languageCode});

/// to get the fonts download method just call [fontsDownloadMethod]
QuranLibrary().fontsDownloadMethod;

Tafsir 
Usage Example 
// get current list


final all = TafsirController.instance.items; // includes defaults + customs

// add a custom sql file (File is from file picker)

final added = await TafsirController.instance.addCustomFromFile(

  sourceFile: pickedFile,

  displayName: 'My Custom Tafsir',

  bookName: 'My Book',

  type: TafsirFileType.json,

);
/// Show a popup menu to change the tafsir style.
QuranLibrary().changeTafsirPopupMenu(TafsirStyle tafsirStyle, {int? pageNumber});

/// Fetch tafsir for a specific page by its page number.
QuranLibrary().fetchTafsir({required int pageNumber});

/// Check if the tafsir is already downloaded.
QuranLibrary().getTafsirDownloaded(int index);

/// Get the list of tafsir and translation names.
QuranLibrary().tafsirAndTraslationCollection;

/// Change the selected tafsir when the switch button is pressed.
QuranLibrary().changeTafsirSwitch(int index, {int? pageNumber});

/// Get the list of available tafsir data.
QuranLibrary().tafsirList;

/// Get the list of available translations.
QuranLibrary().translationList;

/// Fetch translations from the source.
QuranLibrary().fetchTranslation();

/// Download the tafsir by the given index.
QuranLibrary().tafsirDownload(int i);

/// (Optional) Download Tajweed (ayah-level) data used inside the Tafsir bottom sheet
if (!QuranLibrary().isTajweedAyahDownloaded) {
  await QuranLibrary().downloadTajweedAyah();
}

Audio Playback 
This section provides comprehensive capabilities for audio playback of the Holy Quran with background playback support and advanced audio file management. 
Verse Audio Playback 
/// Play a verse or group of verses starting from a specific verse
await QuranLibrary().playAyah(
  context: context,
  currentAyahUniqueNumber: 1, // Unique ayah number
  playSingleAyah: true, // true for single ayah, false to continue
);

/// Move to next verse and play it
await QuranLibrary().seekNextAyah(
  context: context,
  currentAyahUniqueNumber: 5,
);

/// Move to previous verse and play it
await QuranLibrary().seekPreviousAyah(
  context: context,
  currentAyahUniqueNumber: 10,
);
Surah Audio Playback 
/// Play a complete surah from beginning to end
await QuranLibrary().playSurah(surahNumber: 1); // Al-Fatihah
await QuranLibrary().playSurah(surahNumber: 2); // Al-Baqarah

/// Move to next surah and play it
await QuranLibrary().seekToNextSurah();

/// Move to previous surah and play it
await QuranLibrary().seekToPreviousSurah();

Download Management 
/// Start downloading a surah for offline playback
await QuranLibrary().startDownloadSurah(surahNumber: 1);

/// Cancel ongoing download
QuranLibrary().cancelDownloadSurah();
Position Control & Resume 
/// Get current/last surah number
int currentSurah = QuranLibrary().currentAndLastSurahNumber;

/// Get last position as formatted text (like "05:23")
String lastTimeText = QuranLibrary().formatLastPositionToTime;

/// Get last position as Duration object for programming operations
Duration lastDuration = QuranLibrary().formatLastPositionToDuration;

/// Play from the last position where user stopped
await QuranLibrary().playLastPosition();
Complete Audio Example 
class AudioControlExample extends StatefulWidget {
  @override
  _AudioControlExampleState createState() => _AudioControlExampleState();
}

class _AudioControlExampleState extends State<AudioControlExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quran Audio Player')),
      body: Column(
        children: [
          // Display current surah
          Text('Current Surah: ${QuranLibrary().currentAndLastSurahNumber}'),
          
          // Display last position
          Text('Last Position: ${QuranLibrary().formatLastPositionToTime}'),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Play from last position
              ElevatedButton(
                onPressed: () => QuranLibrary().playLastPosition(),
                child: Text('Resume from where you left'),
              ),
              
              // Play Al-Fatihah
              ElevatedButton(
                onPressed: () => QuranLibrary().playSurah(surahNumber: 1),
                child: Text('Surah Al-Fatihah'),
              ),
            ],
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous surah
              IconButton(
                onPressed: () => QuranLibrary().seekToPreviousSurah(),
                icon: Icon(Icons.skip_previous),
              ),
              
              // Previous ayah
              IconButton(
                onPressed: () => QuranLibrary().seekPreviousAyah(
                  context: context,
                  currentAyahUniqueNumber: 10,
                ),
                icon: Icon(Icons.fast_rewind),
              ),
              
              // Next ayah
              IconButton(
                onPressed: () => QuranLibrary().seekNextAyah(
                  context: context,
                  currentAyahUniqueNumber: 5,
                ),
                icon: Icon(Icons.fast_forward),
              ),
              
              // Next surah
              IconButton(
                onPressed: () => QuranLibrary().seekToNextSurah(),
                icon: Icon(Icons.skip_next),
              ),
            ],
          ),
          
          // Download buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => QuranLibrary().startDownloadSurah(surahNumber: 2),
                child: Text('Download Surah Al-Baqarah'),
              ),
              
              ElevatedButton(
                onPressed: () => QuranLibrary().cancelDownloadSurah(),
                child: Text('Cancel Download'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
You can also use the default Quran font or Naskh font 
/// [hafsStyle] is the default style for Quran so all special characters will be rendered correctly
QuranLibrary().hafsStyle;

/// [naskhStyle] is the default style for other text.
QuranLibrary().naskhStyle;
Sources 
Quran text and metadata: King Fahd Glorious Quran Printing Complex — Quran Developer Portal

https://qurancomplex.gov.sa/quran-dev/
Fonts, Tafsir, and Translations: Quranic Universal Library (QUL) by Tarteel

https://qul.tarteel.ai/
License 
MIT for code. QCF fonts are provided via Quranic Universal Library (QUL). Ensure you comply with QUL terms (and any upstream KFGQPC terms) when distributing applications that include or bundle these assets.

Read more about the license here.

For additional terms regarding QCF fonts and QUL resources, see NOTICE.

83
likes
140
points
1.3k
downloads
Documentation
Documentation
API reference

Publisher
verified publisheralheekmahlib.com

Weekly Downloads
2025.09.06 - 2026.08.01
Metadata
An integrated package for displaying the Holy Qur’an identical to the Medina Quran with the narration of Hafs on the authority of Asim.

Repository (GitHub)
View/report issues

License
MIT (license)

Dependencies
arabic_justified_text, archive, audio_service, connectivity_plus, dio, flutter, flutter_scale_kit, flutter_svg, get, get_storage, html, just_audio, just_audio_media_kit, path, path_provider, preload_page_view, rxdart

More
Packages that depend on quran_library

Packages that implement quran_library

Dart languageReport packagePolicyTermsAPI TermsSecurityPrivacyHelpRSSbug report
