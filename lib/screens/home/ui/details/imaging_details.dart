import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_project/cosntants.dart';
import 'package:intl/intl.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_states.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImagingDetailsScreen extends StatefulWidget {
  final int imageId;

  const ImagingDetailsScreen({
    Key? key,
    required this.imageId,
  }) : super(key: key);

  @override
  State<ImagingDetailsScreen> createState() => _ImagingDetailsScreenState();
}

class _ImagingDetailsScreenState extends State<ImagingDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().getMedicalImageDetails(widget.imageId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is MedicalImageDetailsLoaded) {
          final data = state.data;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF036666), width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF036666),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['medicalImageName'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF036666),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is MedicalImageDetailsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MedicalImageDetailsLoaded) {
                  final data = state.data;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            DateFormat('d MMM yyyy').format(
                              DateTime.parse(
                                  data['date'] ?? DateTime.now().toString()),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (data['imageUrl'] != null) ...[
                          Center(
                            child: Container(
                              width: double.infinity,
                              height: 350,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: const Color(0xFF036666), width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: FutureBuilder<String>(
                                  future: _downloadAndGetImagePath(
                                    '$baseUrl/Document/download-file?filePath=${data['imageUrl']}',
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              'Error loading image: ${snapshot.error}'));
                                    } else if (snapshot.hasData) {
                                      return Image.file(
                                        File(snapshot.data!),
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return const Center(
                                        child: Text('No image available'));
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailCard(
                          title: 'Patient Name',
                          value: data['patientName'] ?? '',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailCard(
                          title: 'National ID',
                          value: data['patientNationalId'] ?? '',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailCard(
                          title: 'Interpretation',
                          value: data['interpretation'] ?? '',
                        ),
                      ],
                    ),
                  );
                } else if (state is MedicalImageDetailsError) {
                  return Center(child: Text(state.message));
                }
                return const Center(child: Text('No data available'));
              },
            ),
          );
        } else if (state is MedicalImageDetailsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MedicalImageDetailsError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Future<String> _downloadAndGetImagePath(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } else {
      throw Exception('Failed to download image');
    }
  }
}
