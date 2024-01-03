import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'bid_page.dart';


class SettingsPage extends StatelessWidget {
  SettingsPage({Key? key}) : super(key: key);
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Text(
                  'Settings',
                  style: TextStyle(color: Colors.black, fontSize: 20.0),
                ),
                const SizedBox(width: 30.0), // Adjust as needed
              ],
            ),
            // User Profile Container
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.account_circle_rounded, size: 50),
                  const SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10.0),
                      Text('Username: ${user?.displayName ?? ''}'),
                      Text('Email: ${user?.email ?? ''}'),
                      // Add more user details as needed
                    ],
                  ),
                ],
              ),
            ),
            // Added Items Section
            ListTile(
              title: const Row(
                children: [
                  Text(
                    'Added Items',
                    style: TextStyle(fontSize: 20),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                // Navigate to the page displaying user's added items
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  const UserItemsPage(),
                  ),
                );
              },
            ),
            // About Us Section
            ListTile(
              title: const Row(
                children: [
                  Text(
                    'About Us',
                    style: TextStyle(fontSize: 20),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) =>   const AboutUsPage(),
                ),
                );
              },
            ),
            // Terms and Conditions Section
            ListTile(
              title: const Row(
                children: [
                  Text(
                    'Terms and Conditions',
                    style: TextStyle(fontSize: 20),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>   const TermsAndConditionsPage(),
                  ),
                );
              },
            ),
            // App Version Section
            const ListTile(
              title: Row(
                children: [
                  Text(
                    'App Version',
                    style: TextStyle(fontSize: 20,color: Colors.black,fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(' v1.0',style: TextStyle(fontSize: 20,color: Colors.black,fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            // Sign Out Button
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text('Sign out'),
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
}
class UserItemsPage extends StatelessWidget {
  const UserItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Your Items',
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('userID', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No items added yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var itemData = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(itemData['itemName'] ?? 'Item Name'),
                subtitle: Text('Bid End Date: ${_formatAuctionEndTime(itemData['auctionEndDate'].toDate())}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Show a confirmation dialog before deleting the item
                    _showDeleteConfirmationDialog(context, snapshot.data!.docs[index].id);
                  },
                ),
                onTap: () {
                  // Navigate to the bid page for the selected item
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BidPage(itemId: snapshot.data!.docs[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatAuctionEndTime(DateTime endTime) {
    Duration timeDifference = endTime.difference(DateTime.now());
    if (timeDifference.inHours > 0) {
      return 'in ${timeDifference.inHours} ${timeDifference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (timeDifference.inMinutes > 0) {
      return 'in ${timeDifference.inMinutes} ${timeDifference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'ended';
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String itemId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item',style:
            TextStyle(color: Colors.black),),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel',style: TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () async {
                // Delete the item from the database
                await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete',style: TextStyle(color: Colors.red),),
            ),
          ],
        );
      },
    );
  }
}
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('About Us',),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Story',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'Welcome to our bidding platform! We aim to provide a seamless and enjoyable experience for users to buy and sell items through auctions.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Text(
              'Mission',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'Our mission is to connect people through the thrill of bidding. We strive to create a platform where users can discover unique items, engage in fair and exciting auctions, and build a community of enthusiastic bidders.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'Have questions or suggestions? Feel free to reach out to us at support@biddingplatform.com. We value your feedback!',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Terms and Conditions'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Acceptance of Terms',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'By accessing or using our platform, you agree to comply with and be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the platform.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '2. Use of the Platform',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'You agree to use the platform for lawful purposes only. Do not engage in any activity that disrupts the platform\'s functionality or violates the rights of others.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '3. Bidding and Transactions',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'Bidding on items is a binding agreement to purchase. Ensure that you intend to pay for and complete the transaction before placing a bid.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '4. Privacy Policy',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'Our Privacy Policy outlines how we collect, use, and protect your personal information. By using the platform, you consent to our Privacy Policy.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Text(
              '5. Changes to Terms',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'We reserve the right to modify these Terms and Conditions at any time. Please review these terms regularly to stay informed of any changes.',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}