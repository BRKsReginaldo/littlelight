import 'dart:convert';
import 'dart:io';

import 'package:little_light/services/auth/auth.service.dart';
import 'package:little_light/services/littlelight/models/loadout.model.dart';
import 'package:http/http.dart' as http;
import 'package:little_light/services/littlelight/models/tracked_objective.model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum _HttpMethod { get, post }

class LittleLightService {
  String _uuid;
  String _secret;
  static const _uuidPrefKey = "littlelight_device_id";
  static const _secretPrefKey = "littlelight_secret";

  List<int> raidHashes = [
    3660836525,
    2986584050,
    2683538554,
    3181387331,
    1342567285,
  ];

  static final LittleLightService _singleton =
      new LittleLightService._internal();
  factory LittleLightService() {
    return _singleton;
  }
  LittleLightService._internal();

  List<Loadout> _loadouts;
  List<TrackedObjective> _trackedObjectives;


  loadData() async{
    Directory directory = await getApplicationDocumentsDirectory();
    File cached = new File("${directory.path}/cached_raid_hashes.json");
    bool exists = await cached?.exists();
    if (exists) {
      raidHashes = List<int>.from(jsonDecode(cached.readAsStringSync()));
    }
    Uri uri = Uri(
        scheme: 'http',
        host: "www.littlelight.club",
        path: "data/raid_hashes.json");
    http.Response response = await http.get(uri);
    try{
      dynamic json = jsonDecode(response.body);
      raidHashes = List<int>.from(json);
      cached.writeAsString(response.body);
    }catch(e){
      print(e);
      print("cant load raid hashes");
    }
  }

  Future<List<Loadout>> getLoadouts({forceFetch: false}) async {
    if (_loadouts != null && !forceFetch) return _loadouts;
    await _loadLoadoutsFromCache();
    if (forceFetch) {
      await _fetchLoadouts();
    }
    return _loadouts;
  }

  Future<List<Loadout>> _loadLoadoutsFromCache() async {
    Directory directory = await getApplicationDocumentsDirectory();
    File cached = new File("${directory.path}/cached_loadouts.json");
    bool exists = await cached.exists();
    if (exists) {
      try {
        String json = await cached.readAsString();
        List<dynamic> list = jsonDecode(json);
        List<Loadout> loadouts = Loadout.fromList(list);
        this._loadouts = loadouts;
        this._loadouts.sort((a, b) => a.name.compareTo(b.name));
        return loadouts;
      } catch (e) {}
    }
    return null;
  }

  Future<List<Loadout>> _fetchLoadouts() async {
    dynamic json = await _authorizedRequest("loadouts");
    List<Loadout> _fetchedLoadouts = Loadout.fromList(json['data']);
    if (_loadouts == null) {
      _loadouts = _fetchedLoadouts;
    } else {
      _fetchedLoadouts.forEach((loadout) {
        int index =
            _loadouts.indexWhere((l) => l.assignedId == loadout.assignedId);
        if (index > -1 &&
            _loadouts[index].updatedAt.isAfter(loadout.updatedAt)) {
          _loadouts.replaceRange(index, index + 1, [loadout]);
        } else if (index == -1) {
          _loadouts.add(loadout);
        }
      });
    }
    _saveLoadoutsToStorage();
    this._loadouts.sort((a, b) {
      var nameA = a.name ?? "";
      var nameB = b.name ?? "";
      return nameA.compareTo(nameB);
    });
    return _loadouts;
  }

  Future<int> saveLoadout(Loadout loadout) async {
    loadout.updatedAt = DateTime.now();
    bool exists = _loadouts.any((l) => l.assignedId == loadout.assignedId);
    if (exists) {
      int index =
          _loadouts.indexWhere((l) => l.assignedId == loadout.assignedId);
      _loadouts.replaceRange(index, index + 1, [loadout]);
    } else {
      _loadouts.add(loadout);
    }
    this._loadouts.sort((a, b) => a.name.compareTo(b.name));
    await _saveLoadoutsToStorage();
    return await _saveLoadoutToServer(loadout);
  }

  Future<int> _saveLoadoutToServer(Loadout loadout) async {
    Map<String, dynamic> map = loadout.toMap();
    String body = jsonEncode(map);
    dynamic json = await _authorizedRequest("loadouts/save",
        method: _HttpMethod.post, body: body);
    return json["result"] ?? 0;
  }

  Future<int> deleteLoadout(Loadout loadout) async {
    _loadouts.removeWhere((l) => l.assignedId == loadout.assignedId);
    await _saveLoadoutsToStorage();
    return await _deleteLoadoutOnServer(loadout);
  }

  Future<int> _deleteLoadoutOnServer(Loadout loadout) async {
    Map<String, dynamic> map = loadout.toMap();
    String body = jsonEncode(map);
    dynamic json = await _authorizedRequest("loadouts/delete",
        method: _HttpMethod.post, body: body);
    return json["result"] ?? 0;
  }

  Future<void> _saveLoadoutsToStorage() async {
    Directory directory = await getApplicationDocumentsDirectory();
    File cached = new File("${directory.path}/cached_loadouts.json");

    //TODO: remove this hack when 1.3.8 is old news
    Set<String> _ids = Set();
    List<Loadout> distinctLoadouts = _loadouts.where((l) {
      bool exists = _ids.contains(l.assignedId);
      _ids.add(l.assignedId);
      return !exists;
    }).toList();

    List<dynamic> map = distinctLoadouts.map((l) => l.toMap()).toList();
    String json = jsonEncode(map);
    await cached.writeAsString(json);
  }

  Future<List<TrackedObjective>> getTrackedObjectives() async {
    if (_trackedObjectives != null) return _trackedObjectives;
    await _loadTrackedObjectivesFromCache();
    return _trackedObjectives;
  }

  Future<List<TrackedObjective>> _loadTrackedObjectivesFromCache() async {
    Directory directory = await getApplicationDocumentsDirectory();
    File cached = new File("${directory.path}/tracked_objectives.json");
    bool exists = await cached.exists();
    if (exists) {
      try {
        String json = await cached.readAsString();
        List<dynamic> list = jsonDecode(json);
        List<TrackedObjective> objectives = TrackedObjective.fromList(list);
        this._trackedObjectives = objectives;
        return objectives;
      } catch (e) {}
    }
    this._trackedObjectives = [];
    return this._trackedObjectives;
  }

  Future<void> addTrackedObjective(
      TrackedObjectiveType type, int hash, {String instanceId, String characterId, int parentHash}) async {
        var found = _trackedObjectives.firstWhere((o) => o.type == type && o.hash == hash && o.instanceId == instanceId && characterId == o.characterId, orElse: ()=>null);
    if(found == null){
      _trackedObjectives.add(TrackedObjective(type, hash, instanceId:instanceId, characterId:characterId, parentHash: parentHash));
    }
    await _saveTrackedObjectives();
  }

  Future<void> removeTrackedObjective(
      TrackedObjectiveType type, int hash, {String instanceId, String characterId}) async {
    _trackedObjectives.removeWhere(
        (o) => o.type == type && o.hash == hash && o.instanceId == instanceId && o.characterId == o.characterId);
    await _saveTrackedObjectives();
  }

  Future<void> _saveTrackedObjectives() async {
    Directory directory = await getApplicationDocumentsDirectory();
    File cached = new File("${directory.path}/tracked_objectives.json");
    List<dynamic> map = _trackedObjectives.where((l)=>l.hash != null).map((l) => l.toMap()).toList();
    String json = jsonEncode(map);
    await cached.writeAsString(json);
  }

  Future<dynamic> _authorizedRequest(String path,
      {Map<String, dynamic> customParams,
      String body = "",
      _HttpMethod method = _HttpMethod.get}) async {
    AuthService auth = AuthService();
    SavedMembership membership = await auth.getMembership();
    SavedToken token = await auth.getToken();
    String uuid = await _getUuid();
    String secret = await _getSecret();
    Map<String, dynamic> params = {
      'membership_id': membership.selectedMembership.membershipId,
      'membership_type': "${membership.selectedMembership.membershipType}",
      'uuid': uuid,
    };
    if (secret != null) {
      params['secret'] = secret;
    }
    Uri uri = Uri(
        scheme: 'http',
        host: "www.littlelight.club",
        path: "api/v2/$path",
        queryParameters: params);
    Map<String, String> headers = {
      'Authorization': token.accessToken,
      'Accept': 'application/json'
    };
    http.Response response;
    if (method == _HttpMethod.get) {
      response = await http.get(uri, headers: headers);
    } else {
      headers["Content-Type"] = "application/json";
      response = await http.post(uri, headers: headers, body: body);
    }
    dynamic json = jsonDecode(response.body);
    if (json['secret'] != null) {
      _setSecret(json['secret']);
    }
    return json;
  }

  Future<String> _getUuid() async {
    if (_uuid != null) return _uuid;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String uuid = prefs.getString(_uuidPrefKey);
    if (uuid == null) {
      uuid = Uuid().v4();
      prefs.setString(_uuidPrefKey, uuid);
      _uuid = uuid;
    }
    return uuid;
  }

  Future<String> _getSecret() async {
    if (_secret != null) return _secret;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String secret = prefs.getString(_secretPrefKey);
    _secret = secret;
    return secret;
  }

  _setSecret(String secret) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(_secretPrefKey, secret);
    _secret = secret;
  }

  Future<void> clearData() async {
    this._loadouts = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(_secretPrefKey);
    Directory directory = await getApplicationDocumentsDirectory();
    File cached = new File("${directory.path}/cached_loadouts.json");
    bool exists = await cached.exists();
    if (exists) {
      await cached.delete();
    }
  }
}
