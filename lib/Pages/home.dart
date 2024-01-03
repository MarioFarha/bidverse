import 'package:bidverse/Pages/setting.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'addItem.dart';
import 'bid_page.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  String receivedItemID = '';
  String _formatAuctionEndTime(DateTime endTime) {
    Duration timeDifference = endTime.difference(DateTime.now());
    if (timeDifference.inHours > 0) {
      return 'in ${timeDifference.inHours} ${timeDifference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (timeDifference.inMinutes > 0) {
      return 'in ${timeDifference.inMinutes} ${timeDifference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'now';
    }
  }

  late TextEditingController _searchController;


  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  List<Map<String, dynamic>> _filteredItems = [];

  void _filterItems(String searchTerm) {
    _filteredItems = _items
        .where((item) => item['itemName'].toLowerCase().contains(searchTerm.toLowerCase()))
        .toList();
    setState(() {});
  }

  List<Map<String, dynamic>> _items = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Bidverse',
                  style: TextStyle(
                    fontSize: 35.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.9),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.search),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _filterItems(value);
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search...',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.tune_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Available Items:',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10.0),
              Expanded(
                child: _buildItemsList(),
              ),
              const SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Handle chat button press
                        },
                        icon: const Icon(Icons.chat),
                        color: Colors.black,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const  AddItem(),
                            ),
                        ).then((value) {

                            if (value != null && value.isNotEmpty) {
                            setState(() {
                            receivedItemID = value;
                            });
                            }
                          });
                              },
                        icon: const Icon(Icons.add),
                        color: Colors.black,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingsPage()),
                          );
                        },
                        icon: const Icon(Icons.settings_rounded),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          _items = snapshot.data!.docs.map((itemDoc) {
            return itemDoc.data() as Map<String, dynamic>;
          }).toList();

          final itemsToDisplay = _searchController.text.isEmpty ? _items : _filteredItems;

          return ListView.builder(
            itemCount: itemsToDisplay.length,
            itemBuilder: (context, index) {
              var itemData = itemsToDisplay[index];
              String itemId = snapshot.data!.docs[index].id;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BidPage(itemId: itemId),
                    ),
                  );
                },

              child: _buildItem(
                itemName: itemData['itemName'],
                itemImage: itemData['imageUrl'],
                startingBid: '\$${itemData['startingBidPrice']}',
                auctionEndTime: itemData['auctionEndDate'],) // Customize as needed
              );
            },
          );
        }
      },
    );
  }

  Widget _buildItem({
    required String itemName,
    required String itemImage,
    required String startingBid,
    required Timestamp auctionEndTime,
  }) {
    DateTime endTime = auctionEndTime.toDate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Image.network(
            itemImage,
            width: double.infinity,
            height: 250.0,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              startingBid,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Text(
          'Ends ${_formatAuctionEndTime(endTime)}',
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16.0),
        const Divider(),
      ],
    );
  }
}
