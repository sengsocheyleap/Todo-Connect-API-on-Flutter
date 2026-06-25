import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_connection_api/models/product/Product_response.dart';
import 'package:flutter_connection_api/models/product/Products.dart';
import 'package:http/http.dart' as httpClient;
import 'package:readmore/readmore.dart';
import 'product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Products> productList = [];
  bool isLoading = true;
  bool isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _limit = 5;
  int _skip = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _getFirstLoadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getFirstLoadProducts() async {
    setState(() {
      isLoading = true;
      _skip = 0;
      _hasMoreData = true;
    });

    try {
      String query = _searchController.text.trim();
      Uri uri;

      if (query.isNotEmpty) {
        uri = Uri.parse("https://dummyjson.com/products/search?q=$query");
      } else {
        uri = Uri.parse("https://dummyjson.com/products?limit=$_limit&skip=$_skip");
      }

      var response = await httpClient.get(uri);
      var mapResponse = jsonDecode(response.body);
      var productResponse = ProductResponse.fromJson(mapResponse);

      if (productResponse.products != null) {
        setState(() {
          productList = productResponse.products!;
          _skip = productList.length;

          if (productResponse.products!.length < _limit || query.isNotEmpty) {
            _hasMoreData = false;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoadingMore && _hasMoreData && _searchController.text.isEmpty) {
        setState(() {
          isLoadingMore = true;
        });

        Future.delayed(const Duration(seconds: 5), () async {
          try {
            var uri = Uri.parse("https://dummyjson.com/products?limit=$_limit&skip=$_skip");
            var response = await httpClient.get(uri);
            var mapResponse = jsonDecode(response.body);
            var productResponse = ProductResponse.fromJson(mapResponse);

            if (productResponse.products != null && productResponse.products!.isNotEmpty) {
              setState(() {
                productList.addAll(productResponse.products!);
                _skip = productList.length;

                if (productResponse.products!.length < _limit) {
                  _hasMoreData = false;
                }
                isLoadingMore = false;
              });
            } else {
              setState(() {
                _hasMoreData = false;
                isLoadingMore = false;
              });
            }
          } catch (e) {
            setState(() {
              isLoadingMore = false;
            });
            print("Pagination Error: $e");
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.cyan[700],
        title: const Text(
          "Products Explorer",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _getFirstLoadProducts();
              },
              decoration: InputDecoration(
                hintText: "ស្វែងរកផលិតផល...",
                prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _getFirstLoadProducts();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                : RefreshIndicator(
              color: Colors.cyan[700],
              backgroundColor: Colors.white,
              onRefresh: _getFirstLoadProducts,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                itemCount: productList.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {

                  if (index < productList.length) {
                    var product = productList[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.white,
                              child: product.thumbnail != null
                                  ? Image.network(
                                product.thumbnail!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.contain,
                              )
                                  : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.title ?? "No Title",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.cyan),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailScreen(product: product),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "\$${product.price?.toStringAsFixed(2) ?? '0.00'}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.cyan[700],
                                      ),
                                    ),
                                    if (product.discountPercentage != null && product.discountPercentage! > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Save ${product.discountPercentage}%",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ReadMoreText(
                                  product.description ?? "No description available.",
                                  trimLines: 2,
                                  colorClickableText: Colors.cyan[700],
                                  trimMode: TrimMode.Line,
                                  trimCollapsedText: ' See more',
                                  trimExpandedText: ' See less',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.cyan),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}