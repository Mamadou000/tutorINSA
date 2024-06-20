import 'package:flutter/material.dart';
import 'package:tutorinsa/pages/Common/navigation_bar.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  _VideosPageState createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  int _selectedIndex = 1; // Set the default selected index to Videos

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCategoryRow(String title, List<String> videoTitles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200, // Adjust the height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videoTitles.length,
            itemBuilder: (context, index) {
              return _buildVideoThumbnail(videoTitles[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail(String videoTitle) {
    return GestureDetector(
      onTap: () {
        // Navigate to the specific video's page
      },
      child: Container(
        width: 140, // Adjust the width as needed
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
          image: const DecorationImage(
            image: NetworkImage(
              'https://via.placeholder.com/150', // Replace with your thumbnail image
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(8.0),
            child: Text(
              videoTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> categories = [
      {'title': '1A STPI', 'videos': ['General']},
      {'title': '2A PO', 'videos': ['STI', 'MRI', 'GSI']},
      {'title': '3A', 'videos': ['STI', 'MRI', 'ERE', 'GSI']},
      {'title': '4A', 'videos': ['STI', 'MRI', 'ERE', 'GSI']},
      {'title': '5A', 'videos': ['STI', 'MRI', 'ERE', 'GSI']},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFF5F67EA),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          var category = categories[index];
          return _buildCategoryRow(category['title'], category['videos']);
        },
      ),
      bottomNavigationBar: NavigationBar2(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
