import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BidPage extends StatefulWidget {
  final String itemId;

  const BidPage({Key? key, required this.itemId}) : super(key: key);

  @override
  BidPageState createState() => BidPageState();
}

class BidPageState extends State<BidPage> {
  late TextEditingController bidController;
  late double currentBid;
  late double startingBidPrice;
  final _formKey = GlobalKey<FormState>();
  late bool auctionEnded;
  late String winnerUsername;

  @override
  void initState() {
    super.initState();
    bidController = TextEditingController();
    currentBid = 0.0;
    startingBidPrice = 0.0;
    auctionEnded = false;
    winnerUsername = '';
    _updateCurrentBid();
    _fetchStartingBidPrice();
    _checkAuctionStatus();
  }

  @override
  void dispose() {
    bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('items').doc(
              widget.itemId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            var itemData = snapshot.data!.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(
                  itemData['userID']).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                }

                var userData = userSnapshot.data?.data() as Map<String,
                    dynamic>;

                return SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom header with "Back" button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.arrow_back),
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8.0),
                              const Text(
                                'Bid Page',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Display item image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            itemData['imageUrl'],
                            width: double.infinity,
                            height: 250.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Display item name
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            itemData['itemName'],
                            style: const TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Display auction end date
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            'Auction Ends: ${_formatAuctionEndTime(
                                itemData['auctionEndDate'].toDate())}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        // Display item description label
                        const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text(
                            'Item Description:',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Display item description
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            itemData['description'],
                            style: const TextStyle(
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                        // Display user information and chat button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // User icon (replace with actual user icon)
                              const Icon(
                                  Icons.account_circle_rounded, size: 36.0),
                              const SizedBox(width: 8.0),
                              // User name
                              Text(
                                userData['username'] ?? 'User',
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              // Chat button
                              ElevatedButton(
                                onPressed: () {
                                  // Implement chat functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                ),
                                child: const Text(
                                  'Chat',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add the bid logic here
                        // Starting bid price
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            'Starting Bid: \$${startingBidPrice.toStringAsFixed(
                                2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Current bid price
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            'Current Bid: \$${currentBid.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Bid text field
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: bidController,
                            decoration: const InputDecoration(
                              labelText: 'Enter Your Bid',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your bid';
                              }
                              double enteredBid = double.tryParse(value) ?? 0.0;
                              if (enteredBid <= currentBid) {
                                return 'Bid must be higher than the current bid (\$${currentBid
                                    .toStringAsFixed(2)})';
                              }
                              if (enteredBid <= startingBidPrice) {
                                return 'Bid must be higher than the starting bid price (\$${startingBidPrice
                                    .toStringAsFixed(2)})';
                              }
                              return null; // Return null if the entered bid is valid
                            },
                          ),
                        ),
                        // Place Bid button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: auctionEnded ? null : () {
                              if (_formKey.currentState!.validate()) {
                                _placeBid();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                            child: Text(
                                auctionEnded ? 'Auction Ended' : 'Place Bid'),
                          ),
                        ),
                        // Display winner information
                        if (auctionEnded)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Winner: $winnerUsername with a bid of \$${currentBid
                                  .toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatAuctionEndTime(DateTime endTime) {
    Duration timeDifference = endTime.difference(DateTime.now());
    if (timeDifference.inHours > 0) {
      return 'in ${timeDifference.inHours} ${timeDifference.inHours == 1
          ? 'hour'
          : 'hours'}';
    } else if (timeDifference.inMinutes > 0) {
      return 'in ${timeDifference.inMinutes} ${timeDifference.inMinutes == 1
          ? 'minute'
          : 'minutes'}';
    } else {
      return 'ended';
    }
  }

  void _updateCurrentBid() async {
    try {
      // Fetch the latest bid for the current item from the 'bids' collection
      QuerySnapshot bidSnapshot = await FirebaseFirestore.instance
          .collection('bids')
          .where('itemId', isEqualTo: widget.itemId)
          .orderBy('bidAmount', descending: true)
          .limit(1)
          .get();

      if (bidSnapshot.docs.isNotEmpty) {
        // If there is a bid for this item, update the currentBid
        setState(() {
          currentBid = bidSnapshot.docs.first['bidAmount'];
        });
      }
    } catch (error) {
      print('Error updating current bid: $error');
    }
  }

  void _placeBid() async {
    // Add your bid logic here
    double newBid = double.tryParse(bidController.text) ?? 0.0;

    if (newBid > currentBid) {
      setState(() {
        currentBid = newBid;
      });

      // Add bid to the 'bids' collection
      await FirebaseFirestore.instance.collection('bids').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'itemId': widget.itemId,
        'bidAmount': newBid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Check if the auction has ended after placing a bid
      _checkAuctionStatus();
    } else {
      // Show an error message or handle invalid bid
    }
  }

  void _fetchStartingBidPrice() async {
    try {
      // Fetch the starting bid price from the 'items' collection
      DocumentSnapshot itemSnapshot =
      await FirebaseFirestore.instance.collection('items')
          .doc(widget.itemId)
          .get();

      if (itemSnapshot.exists) {
        setState(() {
          startingBidPrice = itemSnapshot['startingBidPrice'];
        });
      }
    } catch (error) {
      print('Error fetching starting bid price: $error');
    }
  }

  void _checkAuctionStatus() async {
    try {
      // Fetch the item data to check the auction end date
      DocumentSnapshot itemSnapshot =
      await FirebaseFirestore.instance.collection('items')
          .doc(widget.itemId)
          .get();

      if (itemSnapshot.exists) {
        DateTime auctionEndDate = itemSnapshot['auctionEndDate'].toDate();
        DateTime now = DateTime.now();

        // If the current time is after the auction end date, update the winner information
        if (now.isAfter(auctionEndDate)) {
          // Fetch the highest bid to determine the winner
          QuerySnapshot bidSnapshot = await FirebaseFirestore.instance
              .collection('bids')
              .where('itemId', isEqualTo: widget.itemId)
              .orderBy('bidAmount', descending: true)
              .limit(1)
              .get();

          if (bidSnapshot.docs.isNotEmpty) {
            String winnerUserId = bidSnapshot.docs.first['userId'];
            DocumentSnapshot winnerUserSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(
                winnerUserId).get();

            if (winnerUserSnapshot.exists) {
              setState(() {
                auctionEnded = true;
                winnerUsername = winnerUserSnapshot['username'];
              });

              // Display winner information in a dialog
              _showWinnerDialog();
            }
          }
        }
      }
    } catch (error) {
      print('Error checking auction status: $error');
    }
  }

  void _showWinnerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Auction Ended!',style: TextStyle(color: Colors.red),),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Winner: $winnerUsername'),
              Text('Bid Amount: \$${currentBid.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}