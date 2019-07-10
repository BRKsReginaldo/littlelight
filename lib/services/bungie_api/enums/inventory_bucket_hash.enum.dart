class InventoryBucket {
  static const int kineticWeapons = 1498876634;
  static const int energyWeapons = 2465295065;
  static const int powerWeapons = 953998645;
  static const int ghost = 4023194814;
  static const int helmet = 3448274439;
  static const int gauntlets = 3551918588;
  static const int chestArmor = 14239492;
  static const int legArmor = 20886954;
  static const int classArmor = 1585787867;
  static const int vehicle = 2025709351;
  static const int ships = 284967655;
  static const int emblems = 4274335291;
  static const int emotes = 3054419239;
  static const int lostItems = 215593132;
  static const int general = 138197802;
  static const int consumables = 1469714392;
  static const int shaders = 2973005342;
  static const int specialOrders = 1367666825;
  static const int upgradePoint = 2689798304;
  static const int glimmer = 2689798308;
  static const int legendaryShards = 2689798309;
  static const int strangeCoin = 2689798305;
  static const int silver = 2689798310;
  static const int brightDust = 2689798311;
  static const int messages = 3161908920;
  static const int subclass = 3284755031;
  static const int modifications = 3313201758;
  static const int materials = 3865314626;
  static const int clanBanners = 4292445962;
  static const int engrams = 375726501;
  static const int pursuits = 1345459588;
}

const List<int> exoticWeaponBlockBuckets = [
  InventoryBucket.kineticWeapons,
  InventoryBucket.energyWeapons,
  InventoryBucket.powerWeapons,
];

const List<int> exoticArmorBlockBuckets = [
  InventoryBucket.helmet,
  InventoryBucket.gauntlets,
  InventoryBucket.chestArmor,
  InventoryBucket.legArmor,
];

const List<int> loadoutBucketHashes = [
  InventoryBucket.subclass,
  InventoryBucket.kineticWeapons,
  InventoryBucket.energyWeapons,
  InventoryBucket.powerWeapons,
  InventoryBucket.helmet,
  InventoryBucket.gauntlets,
  InventoryBucket.chestArmor,
  InventoryBucket.legArmor,
  InventoryBucket.classArmor,
  InventoryBucket.ghost,
  InventoryBucket.vehicle,
  InventoryBucket.ships,
];
