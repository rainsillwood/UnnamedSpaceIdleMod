# UnnamedSpaceIdleMod

修改教程:https://www.bilibili.com/opus/1132720787400163332

下面是已经修改过的文件,按路径导入即可

1.RedeemCode:
- 增加过期兑换码的兑换
- 加可以无限使用的作弊码,这些作弊码的效果可能会随关卡的提升而提升(暂未实现)
```
medium rare please
<censored>
give me liberty or give me coin
trade plz
social media
nova & orion
whats mine is mine
breathe deep
cheese steak jimmy's
lumberjack
rock on
robinhood
a whole lot of love
```

2.EnergyVoid:
- 将点击虚空能量时立刻获得的虚空能量从3分钟的当前净收入改为void_power_generation*void_power_conversion_max*energy_void_power_gain(破坏平衡,把虚空能量上限堆高以后基本不需要投入虚空物质都能4x超载)

3.EventHelper:
- 以一个活动15天为周期轮换活动,周期最初开始时间为UTC0秒,最后一天休息时间

4.PurchaseHelper:
- 破解内购

5.SynthModuleArea:
- 增加5个模块位置,注意是在启用时临时增加5的判定上限,因此开游戏的时候会关掉超过上限的,需要重新开启(破坏平衡,本人为了启用几个自动化模块改的)

6.ComputeArea:
- 将算力以2的倍数向上取整(基本平衡,最多临时多出1的算力,本人强迫症)

7.DBImport:
- 修改自动使用三件套,去除debuff,1-4级增加持续时间,4级时持续时间=CD(破坏平衡)
- 增加合成无限升级,需要配合LimitedUpgradeButton,SynthPointsArea,否则无法使用
```
21600000 TimeFlux = 1 * 6h时间加速
10min时间加速 = 600000 TimeFlux
10min资源加速 = 46875 TimeFlux
10min合成加速 = 62500 TimeFlux
10min研究加速 = 75000 TimeFlux
10min基地加速 = 93750 TimeFlux
10min跃迁加速 = 93750 TimeFlux
10min船员加速 = 93750 TimeFlux
10min舰队加速 = 125000 TimeFlux
```
- 增加新资源TimeFlux,1点相当于1ms离线时间
- 修改活动奖励:
```
2 Giftium = 300000 TimeFlux
2 Yearium = 300000 TimeFlux
Spaceversary其他兑换奖励均变为 1125000 TimeString
```

8.SaveLoad:
- 导入导出存档均不进行gzip和base64,直接导出JSON

9.LimitedUpgradeButton
- 修改升级逻辑,当最大等级为0时,修改最大等级为int32,同时重置等级

10.SynthPointsArea
- 在合成升级界面加上TimeFlux显示