import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/blog.dart';
import '../models/blog_model.dart';
class BlogRemoteDataSource {
 final ApiClient api; BlogRemoteDataSource(this.api);
 Future<List<Blog>> all() async { try { final r=await api.get('/blogs'); return (r.data['blogs'] as List).map((e)=>BlogModel.fromJson(Map<String,dynamic>.from(e))).toList(); } catch(e){throw api.exceptionFrom(e);} }
 Future<Blog> create(String name,String description,XFile? image) async { try { final data=FormData.fromMap({'name':name,'description':description}); if(image!=null) data.files.add(MapEntry('img',await MultipartFile.fromFile(image.path,filename:image.name))); final r=await api.post('/blogs',data:data); return BlogModel.fromJson(Map<String,dynamic>.from(r.data['blog'])); } catch(e){throw api.exceptionFrom(e);} }
 Future<Blog> update(int id,String name,String description,XFile? image) async { try { final data=FormData.fromMap({'_method':'PUT','name':name,'description':description}); if(image!=null) data.files.add(MapEntry('img',await MultipartFile.fromFile(image.path,filename:image.name))); final r=await api.post('/blogs/$id',data:data); return BlogModel.fromJson(Map<String,dynamic>.from(r.data['blog'])); } catch(e){throw api.exceptionFrom(e);} }
 Future<void> delete(int id) async { try { await api.delete('/blogs/$id'); } catch(e){throw api.exceptionFrom(e);} }
}
