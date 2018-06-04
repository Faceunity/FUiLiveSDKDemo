 //
//  LiveViewController.m
//  TILLiveSDKShow
//
//  Created by wilderliao on 16/11/9.
//  Copyright © 2016年 Tencent. All rights reserved.
//

#import "LiveViewController.h"

#import "UIImage+TintColor.h"
#import "UIColor+MLPFlatColors.h"

#import "LiveViewController+UI.h"
#import "LiveViewController+ImListener.h"
#import "LiveViewController+AVListener.h"
#import "LiveViewController+Audio.h"

#import "LiveCallView.h"


#import "FUManager.h"
#import <FUAPIDemoBar/FUAPIDemoBar.h>


@interface LiveViewController ()<QAVLocalVideoDelegate, QAVRemoteVideoDelegate,ILiveRoomDisconnectListener,TXIVideoPreprocessorDelegate,
UIGestureRecognizerDelegate,
FUAPIDemoBarDelegate>

@property (nonatomic, strong) NSTimer *heartTimer;

/**     -------- FaceUnity --------     **/
@property (nonatomic, strong) FUAPIDemoBar *demoBar ;
/**     -------- FaceUnity --------     **/
@end

@implementation LiveViewController

/**     -------- FaceUnity --------     **/

- (void)OnLocalVideoRawSampleBuf:(CMSampleBufferRef)buf result:(CMSampleBufferRef *)ret {
    
    CVPixelBufferRef pixelBffer = CMSampleBufferGetImageBuffer(buf) ;
    
    [[FUManager shareManager] renderItemsToPixelBuffer:pixelBffer ];
}

-(FUAPIDemoBar *)demoBar {
    if (!_demoBar) {
        
        _demoBar = [[FUAPIDemoBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 164 - 44, self.view.frame.size.width, 164)];
        
        _demoBar.itemsDataSource = [FUManager shareManager].itemsDataSource;
        _demoBar.selectedItem = [FUManager shareManager].selectedItem ;
        
        _demoBar.filtersDataSource = [FUManager shareManager].filtersDataSource ;
        _demoBar.beautyFiltersDataSource = [FUManager shareManager].beautyFiltersDataSource ;
        _demoBar.filtersCHName = [FUManager shareManager].filtersCHName ;
        _demoBar.selectedFilter = [FUManager shareManager].selectedFilter ;
        [_demoBar setFilterLevel:[FUManager shareManager].selectedFilterLevel forFilter:[FUManager shareManager].selectedFilter] ;
        
        _demoBar.skinDetectEnable = [FUManager shareManager].skinDetectEnable;
        _demoBar.blurShape = [FUManager shareManager].blurShape ;
        _demoBar.blurLevel = [FUManager shareManager].blurLevel ;
        _demoBar.whiteLevel = [FUManager shareManager].whiteLevel ;
        _demoBar.redLevel = [FUManager shareManager].redLevel;
        _demoBar.eyelightingLevel = [FUManager shareManager].eyelightingLevel ;
        _demoBar.beautyToothLevel = [FUManager shareManager].beautyToothLevel ;
        _demoBar.faceShape = [FUManager shareManager].faceShape ;
        
        _demoBar.enlargingLevel = [FUManager shareManager].enlargingLevel ;
        _demoBar.thinningLevel = [FUManager shareManager].thinningLevel ;
        _demoBar.enlargingLevel_new = [FUManager shareManager].enlargingLevel_new ;
        _demoBar.thinningLevel_new = [FUManager shareManager].thinningLevel_new ;
        _demoBar.jewLevel = [FUManager shareManager].jewLevel ;
        _demoBar.foreheadLevel = [FUManager shareManager].foreheadLevel ;
        _demoBar.noseLevel = [FUManager shareManager].noseLevel ;
        _demoBar.mouthLevel = [FUManager shareManager].mouthLevel ;
        
        _demoBar.delegate = self;
    }
    return _demoBar ;
}

/**      FUAPIDemoBarDelegate       **/

- (void)demoBarDidSelectedItem:(NSString *)itemName {
    
    [[FUManager shareManager] loadItem:itemName];
}

- (void)demoBarBeautyParamChanged {
    
    [FUManager shareManager].skinDetectEnable = _demoBar.skinDetectEnable;
    [FUManager shareManager].blurShape = _demoBar.blurShape;
    [FUManager shareManager].blurLevel = _demoBar.blurLevel ;
    [FUManager shareManager].whiteLevel = _demoBar.whiteLevel;
    [FUManager shareManager].redLevel = _demoBar.redLevel;
    [FUManager shareManager].eyelightingLevel = _demoBar.eyelightingLevel;
    [FUManager shareManager].beautyToothLevel = _demoBar.beautyToothLevel;
    [FUManager shareManager].faceShape = _demoBar.faceShape;
    [FUManager shareManager].enlargingLevel = _demoBar.enlargingLevel;
    [FUManager shareManager].thinningLevel = _demoBar.thinningLevel;
    [FUManager shareManager].enlargingLevel_new = _demoBar.enlargingLevel_new;
    [FUManager shareManager].thinningLevel_new = _demoBar.thinningLevel_new;
    [FUManager shareManager].jewLevel = _demoBar.jewLevel;
    [FUManager shareManager].foreheadLevel = _demoBar.foreheadLevel;
    [FUManager shareManager].noseLevel = _demoBar.noseLevel;
    [FUManager shareManager].mouthLevel = _demoBar.mouthLevel;
    
    [FUManager shareManager].selectedFilter = _demoBar.selectedFilter ;
    [FUManager shareManager].selectedFilterLevel = _demoBar.selectedFilterLevel;
}

-(void)dealloc {
    
    [[FUManager shareManager] destoryItems];
}

/**     -------- FaceUnity --------     **/

- (instancetype)initWith:(TCShowLiveListItem *)item roomOptionType:(RoomOptionType)type
{
    if (self = [super init])
    {
        _liveItem = item;
        NSString *loginId = [[ILiveLoginManager getInstance] getLoginId];
        _isHost = [loginId isEqualToString:item.uid];
        _roomOptionType = type;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES animated:YES];
//    self.view.backgroundColor = kColorWhite;
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loginbg"]];
    bg.userInteractionEnabled = YES;
    self.view = bg;

    _isFristShow = YES;

    _msgDatas = [NSMutableArray array];
    _preProcessor = [[TXCVideoPreprocessor alloc] init];
    [_preProcessor setDelegate:self];//TXIVideoPreprocessorDelegate
    [[ILiveRoomManager getInstance] setRemoteVideoDelegate:self];

    //初始化直播
    [self initLive];
    //创建房间
    [self enterRoom];
    //发送心跳
    [self startLiveTimer];
//    //添加界面视图
    [self addSubviews];
    //进入房间，上报成员id
    [self reportMemberId:_liveItem.info.roomnum operate:0];
    //添加监听
    [self addObserver];

    //开始网络环境timer
//    [self startEnvTimer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registKeyboard];
    
/**     -------- FaceUnity --------     **/
    [[FUManager shareManager] loadItems];
    [self.view addSubview:self.demoBar];
/**     -------- FaceUnity --------     **/
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unRegistKeyboard];
}

- (void)enterRoom
{
    //进入房间清空美颜，如果不清空，则进入时还会保留上次房间中的美颜值
    QAVContext *context = [[ILiveSDK getInstance] getAVContext];
    [context.videoCtrl inputBeautyParam:0];
    [context.videoCtrl inputWhiteningParam:0];
    
    switch (_roomOptionType)
    {
        case RoomOptionType_CrateRoom:
        {
            [self createRoom:(int)_liveItem.info.roomnum groupId:_liveItem.info.groupid];
            //上报房间信息
            [self reportRoomInfo:(int)_liveItem.info.roomnum groupId:_liveItem.info.groupid];
        }
            break;
        case RoomOptionType_JoinRoom:
        {
            UISwipeGestureRecognizer *downGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwitchToNextRoom:)];
            downGes.direction = UISwipeGestureRecognizerDirectionDown;
            [self.view addGestureRecognizer:downGes];
            
            UISwipeGestureRecognizer *upGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwitchToPreRoom:)];
            upGes.direction = UISwipeGestureRecognizerDirectionUp;
            [self.view addGestureRecognizer:upGes];
            
            [self joinRoom:(int)_liveItem.info.roomnum groupId:_liveItem.info.groupid];
        }
            break;
        default:
            break;
    }
}
    
- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchRoomRefresh:) name:kUserSwitchRoom_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGotupDelete:) name:kGroupDelete_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLikeHeartStartRect:) name:kUserParise_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLiveViewPure:) name:kPureDelete_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLiveViewNoPure:) name:kNoPureDelete_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startLiveTimer) name:kEnterBackGround_Notification object:nil];
}
    
//- (void)startEnvTimer
//{
//    _envInfoTimer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer){
//        QAVContext *context = [[ILiveSDK getInstance] getAVContext];
//        if (context.videoCtrl && context.audioCtrl && context.room)
//        {
//            ILiveQualityData *qualityData = [[ILiveRoomManager getInstance] getQualityData];
//            //if host, Send Recv
//            NSInteger lossRate = qualityData.recvRate;
//            if (_isHost)
//            {
//                lossRate = qualityData.sendLossRate;
//            }
//            EnvInfoItem *item = [[EnvInfoItem alloc] init];
//            item.cpuRate = qualityData.appCPURate;
//            item.lossRate = qualityData.sendLossRate;
//            [_envInfoView configWith:item];
//        }
//    }];
//    [[NSRunLoop currentRunLoop] addTimer:_envInfoTimer forMode:NSDefaultRunLoopMode];
//}

- (void)onLiveViewPure:(NSNotification *)noti
{
    CGRect msgFrame = _msgTableView.frame;
    CGRect closeFrame = _closeBtn.frame;
    _closeBtnRestoreRect = closeFrame;
    _msgRestoreRect = msgFrame;
    [UIView animateWithDuration:0.5 animations:^{
        CGRect moveToRect = CGRectMake(-(msgFrame.origin.x+ msgFrame.size.width), msgFrame.origin.y, msgFrame.size.width, msgFrame.size.height);
        [_msgTableView setFrame:moveToRect];
        CGRect moveClosetToRect = CGRectMake(closeFrame.origin.x, -(closeFrame.origin.y+closeFrame.size.height), closeFrame.size.width, closeFrame.size.height);
        [_closeBtn setFrame:moveClosetToRect];
    } completion:^(BOOL finished) {
        _msgTableView.hidden = YES;
        _closeBtn.hidden = YES;
    }];
}
- (void)onLiveViewNoPure:(NSNotification *)noti
{
    _msgTableView.hidden = NO;
    _closeBtn.hidden = NO;
    [UIView animateWithDuration:0.5 animations:^{
        [_msgTableView setFrame:_msgRestoreRect];
        [_closeBtn setFrame:_closeBtnRestoreRect];
    } completion:^(BOOL finished) {
    }];
}

- (void)onSwitchToPreRoom:(UIGestureRecognizer *)ges
{
    if (ges.state == UIGestureRecognizerStateEnded)
    {
        [self switchRoom:YES];
    }
}

- (void)onSwitchToNextRoom:(UIGestureRecognizer *)ges
{
    if (ges.state == UIGestureRecognizerStateEnded)
    {
        [self switchRoom:NO];
    }
}

- (void)switchRoom:(BOOL)isPreRoom
{
    TILLiveRoomOption *option = [TILLiveRoomOption defaultGuestLiveOption];
    option.controlRole = kSxbRole_GuestHD;
    
    __weak typeof(self) ws = self;
    
    RoomListRequest *listReq = [[RoomListRequest alloc] initWithHandler:^(BaseRequest *request) {
        RoomListRequest *wreq = (RoomListRequest *)request;
        RoomListRspData *respData = (RoomListRspData *)wreq.response.data;
        
        if (respData.rooms.count <= 1)
        {
            [AlertHelp tipWith:@"没有更多房间了" wait:1];
            return ;
        }
        
        int curRoomIndex = -1;
        int switchToIndex = -1;
        for (int index = 0; index < respData.rooms.count; index++ )
        {
            TCShowLiveListItem *item = respData.rooms[index];
            if (item.info.roomnum == ws.liveItem.info.roomnum)
            {
                curRoomIndex = index;
            }
        }
        
        if (isPreRoom)
        {
            if (curRoomIndex == -1)
            {
                switchToIndex = 0;
                
            }
            else if (curRoomIndex > 0)
            {
                switchToIndex = curRoomIndex-1;
            }
            //如果当前房间是第一个，则切换到最后一个房间
            else if (curRoomIndex == 0 && respData.rooms.count > 1)
            {
                switchToIndex = (int)respData.rooms.count-1;
            }
        }
        else
        {
            if (curRoomIndex == -1)
            {
                switchToIndex = 0;
            }
            else if (curRoomIndex < respData.rooms.count - 1)
            {
                switchToIndex = curRoomIndex + 1;
            }
            //如果当前房间是最后一个，则切换到第一个房间
            else if (curRoomIndex == respData.rooms.count-1 && respData.rooms.count > 1)
            {
                switchToIndex = 0;
            }
        }
        //回收上一个房间的资源
        [ws reportMemberId:ws.liveItem.info.roomnum operate:1];//上一个房间退房
        [[UserViewManager shareInstance] releaseManager];//移除渲染画面
        
        TCShowLiveListItem *item = respData.rooms[switchToIndex];
        ws.liveItem = item;
        TILLiveRoomOption *option = [TILLiveRoomOption defaultGuestLiveOption];
        option.controlRole = kSxbRole_GuestHD;
        _isCameraEvent = NO;
        [[ILiveRoomManager getInstance] switchRoom:(int)item.info.roomnum option:option succ:^{
            //更新当前房间
            [ws reportMemberId:item.info.roomnum operate:0];//当前房间进房
            [ws sendJoinRoomMsg];
            
            //如果3S都没有来相机事件，那么就显示对方没有开摄像头的字样,且把背景改成蓝色（增强体验的作用）
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!ws.isCameraEvent) {
                    ws.noCameraDatatalabel.hidden = NO;
                }
            });
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserSwitchRoom_Notification object:item userInfo:nil];
            
        } failed:^(NSString *module, int errId, NSString *errMsg) {
            [ws onClose];
        }];
        
    } failHandler:^(BaseRequest *request) {
        NSLog(@"get room list fail");
    }];
    
    listReq.token = [AppDelegate sharedAppDelegate].token;
    listReq.type = @"live";
    listReq.index = 0;
    listReq.size = 20;
    listReq.appid = [ShowAppId intValue];
    
    [[WebServiceEngine sharedEngine] asyncRequest:listReq];
}

- (void)createRoom:(int)roomId groupId:(NSString *)groupid
{
    __weak typeof(self) ws = self;
    
    TILLiveRoomOption *option = [TILLiveRoomOption defaultHostLiveOption];
    option.controlRole = _liveItem.info.roleName;
    option.avOption.autoHdAudio = YES;//使用高音质模式，可以传背景音乐
    option.roomDisconnectListener = self;
    option.imOption.imSupport = YES;
    
    LoadView *createRoomWaitView = [LoadView loadViewWith:@"正在创建房间"];
    [self.view addSubview:createRoomWaitView];
    
    [[TILLiveManager getInstance] createRoom:(int)_liveItem.info.roomnum option:option succ:^{
        [createRoomWaitView removeFromSuperview];
        
        [_bottomView setMicState:YES];//重新设置麦克风的状态
        
        NSLog(@"createRoom succ");
        //将房间参数保存到本地，如果异常退出，下次进入app时，可提示返回这次的房间
        [ws.liveItem saveToLocal];
        [ws setSelfInfo];
        
        [ws initAudio];
        
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        [createRoomWaitView removeFromSuperview];
        
        NSString *errinfo = [NSString stringWithFormat:@"module=%@,errid=%d,errmsg=%@",module,errId,errMsg];
        NSLog(@"createRoom fail.%@",errinfo);
        [AppDelegate showAlert:ws title:@"创建房间失败" message:errinfo okTitle:@"确定" cancelTitle:nil ok:nil cancel:nil];
    }];
}

- (void)setSelfInfo
{
    __weak typeof(self) ws = self;
    [[TIMFriendshipManager sharedInstance] GetSelfProfile:^(TIMUserProfile *profile) {
        ws.selfProfile = profile;
    } fail:^(int code, NSString *msg) {
        NSLog(@"GetSelfProfile fail");
        ws.selfProfile = nil;
    }];
}

- (void)joinRoom:(int)roomId groupId:(NSString *)groupid
{
    TILLiveRoomOption *option = [TILLiveRoomOption defaultGuestLiveOption];
    option.controlRole = kSxbRole_GuestHD;
    option.avOption.autoHdAudio = YES;

    __weak typeof(self) ws = self;
    [[TILLiveManager getInstance] joinRoom:roomId option:option succ:^{
        NSLog(@"join room succ");
        [ws sendJoinRoomMsg];
        [ws setSelfInfo];

    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSString *errLog = [NSString stringWithFormat:@"join room fail. module=%@,errid=%d,errmsg=%@",module,errId,errMsg];
        [AppDelegate showAlert:self title:@"加入房间失败" message:errLog okTitle:nil cancelTitle:@"退出" ok:nil cancel:^(UIAlertAction * _Nonnull action) {
            [ws dismissViewControllerAnimated:YES completion:nil];
        }];
    }];
}

- (void)sendJoinRoomMsg
{
    ILVLiveCustomMessage *msg = [[ILVLiveCustomMessage alloc] init];
    msg.type = ILVLIVE_IMTYPE_GROUP;
    msg.cmd = (ILVLiveIMCmd)AVIMCMD_EnterLive;
    msg.recvId = [[ILiveRoomManager getInstance] getIMGroupId];
    
    [[TILLiveManager getInstance] sendCustomMessage:msg succ:^{
        NSLog(@"succ");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"fail");
    }];
}

- (void)addSubviews
{
    __weak typeof(self) ws = self;
    
    CGRect selfrect = [UIScreen mainScreen].bounds;
    _noCameraDatatalabel = [[UILabel alloc] initWithFrame:CGRectMake(0, selfrect.size.height/2-44, selfrect.size.width, 44)];
    _noCameraDatatalabel.text = @"主播没有打开摄像头";
    _noCameraDatatalabel.textAlignment = NSTextAlignmentCenter;
    _noCameraDatatalabel.hidden = YES;
    _noCameraDatatalabel.textColor = kColorWhite;
    [self.view addSubview:_noCameraDatatalabel];
    
    //如果5S都没有来相机事件，那么就显示对方没有开摄像头的字样,且把背景改成蓝色（增强体验的作用）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!ws.isCameraEvent) {
            ws.noCameraDatatalabel.hidden = NO;
        }
    });
    
    _closeBtn = [[UIButton alloc] init];
    [_closeBtn setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(onBtnClose:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeBtn];
    
    _topView = [[LiveUITopView alloc] initWith:_liveItem isHost:_isHost];
    _topView.delegate = self;
    [self.view addSubview:_topView];
    
    _parView = [[LiveUIParView alloc] init];
    _parView.delegate = self;
    LiveUIParViewConfig *config = [[LiveUIParViewConfig alloc] init];
    config.isHost = _isHost;
    config.item = _liveItem;
    [_parView configWith:config];
    [self.view addSubview:_parView];
    
    _bgAlphaView = [[UIView alloc] init];
    _bgAlphaView.backgroundColor = [UIColor clearColor];

#warning mark ----- 此处手势有修改。
#pragma mark ------ 此处手势原代码没用加响应判断，会拦截 FUApiDemoBar 的点击响应
#pragma mark ------ 此处修改为 添加代理，实现代理方法，判断是否响应此次点击
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBlankToHide)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    
    tap.delegate = self ;
    
    [_bgAlphaView addGestureRecognizer:tap];
    [self.view addSubview:_bgAlphaView];
    
    UITapGestureRecognizer *hiddenKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBlankToHideKeyboard)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    
    hiddenKeyboard.delegate = self ;
    
    [self.view addGestureRecognizer:hiddenKeyboard];
    
    _reportView = [[ReportView alloc] initWithFrame:CGRectMake(0, -30, self.view.bounds.size.width, self.view.bounds.size.height)];
    _reportView.backgroundColor = [UIColor clearColor];
    _reportView.identifier.text = _liveItem.uid;
    _reportView.hidden = YES;
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapReportViewBlankToHide)];
    tap1.numberOfTapsRequired = 1;
    tap1.numberOfTouchesRequired = 1;
    
    tap1.delegate = self ;
    
    [_reportView addGestureRecognizer:tap1];
    [self.view addSubview:_reportView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectVideoBegin:) name:kClickConnect_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectVideoCancel:) name:kCancelConnect_Notification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downVideo:) name:kClickDownVideo_Notification object:nil];
    
    _memberListView = [[UITableView alloc] init];
    _memberListView.delegate = self;
    _memberListView.dataSource = self;
    _memberListView.tableFooterView = [[UIView alloc] init];
    _memberListView.separatorInset = UIEdgeInsetsZero;
    [_bgAlphaView addSubview:_memberListView];

    _members = [NSMutableArray array];
    _upVideoMembers = [NSMutableArray array];

    _msgTableView = [[UITableView alloc] init];
    _msgTableView.backgroundColor = [UIColor clearColor];
    _msgTableView.delegate = self;
    _msgTableView.dataSource = self;
    _msgTableView.separatorInset = UIEdgeInsetsZero;
    _msgTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _msgTableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_msgTableView];

    _msgInputView = [[MsgInputView alloc] initWith:self];
    _msgInputView.limitLength = 32;
    _msgInputView.hidden = YES;
    [self.view addSubview:_msgInputView];
    
    _bottomView = [[LiveUIBttomView alloc] initWith:kSxbRole_HostHD];
    _bottomView.delegate = self;
    _bottomView.isHost = _isHost;
    _bottomView.preProcessor = _preProcessor;
    _bottomView.curRole = _liveItem.info.roleName;
    [self.view addSubview:_bottomView];
    
//    _envInfoView = [[EnvInfoView alloc] init];
//    _envInfoView.backgroundColor = [kColorBlack colorWithAlphaComponent:0.2];
//    [self.view addSubview:_envInfoView];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    UIView *view = touch.view ;
    
    return view == _bgAlphaView || view == _reportView || view == self.view ;
}

- (LiveUIBttomView *)getBottomView
{
    return _bottomView;
}
- (void)connectVideoBegin:(NSNotification *)noti
{
    [self onTapBlankToHide];//点击连麦时自动收起好友列表
    
    //增加连麦小视图
    NSString *userid = (NSString *)noti.object;
    LiveCallView *callView = [[UserViewManager shareInstance] addPlaceholderView:userid];
    [self.view addSubview:callView];
}

- (void)connectVideoCancel:(NSNotification *)noti
{
    NSString *userId = (NSString *)noti.object;
    [[UserViewManager shareInstance] removePlaceholderView:userId];
    [[UserViewManager shareInstance] refreshViews];
}

- (void)downVideo:(NSNotification *)noti
{
    [self onTapBlankToHide];//点击下麦时自动收起好友列表
}

- (void)initLive
{
    TILLiveManager *manager = [TILLiveManager getInstance];
    [manager setAVListener:self];
    [manager setIMListener:self];
    [manager setAVRootView:self.view];
    
    //如果要使用美颜，必须设置本地视频代理
    [[ILiveRoomManager getInstance] setLocalVideoDelegate:self];
}

- (void)reportRoomInfo:(int)roomId groupId:(NSString *)groupid
{
    ReportRoomRequest *reportReq = [[ReportRoomRequest alloc] initWithHandler:^(BaseRequest *request) {
        NSLog(@"-----> 上传成功");
        
    } failHandler:^(BaseRequest *request) {
        // 上传失败
        NSLog(@"-----> 上传失败");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errinfo = [NSString stringWithFormat:@"code=%ld,msg=%@",(long)request.response.errorCode,request.response.errorInfo];
            [AppDelegate showAlert:self title:@"上传RoomInfo失败" message:errinfo okTitle:@"确定" cancelTitle:nil ok:nil cancel:nil];
        });
    }];
    
    reportReq.token = [AppDelegate sharedAppDelegate].token;
    
    reportReq.room = [[ShowRoomInfo alloc] init];
    reportReq.room.title = _liveItem.info.title;
    reportReq.room.type = @"live";
    reportReq.room.roomnum = roomId;
    reportReq.room.groupid = [NSString stringWithFormat:@"%d",roomId];
    reportReq.room.cover = _liveItem.info.cover.length > 0 ? _liveItem.info.cover : @"";
    reportReq.room.appid = [ShowAppId intValue];
    
    [[WebServiceEngine sharedEngine] asyncRequest:reportReq];
}

- (void)reportMemberId:(NSInteger)roomnum operate:(NSInteger)operate
{
    __weak typeof(self) ws = self;
    ReportMemIdRequest *req = [[ReportMemIdRequest alloc] initWithHandler:^(BaseRequest *request) {
        NSLog(@"report memeber id succ");
        [ws onRefreshMemberList];
        
    } failHandler:^(BaseRequest *request) {
        NSLog(@"report memeber id fail");
    }];
    req.token = [AppDelegate sharedAppDelegate].token;
    req.userId = [[ILiveLoginManager getInstance] getLoginId];
    req.roomnum = roomnum;
    req.role = _isHost ? 1 : 0;
    req.operate = operate;
    
    [[WebServiceEngine sharedEngine] asyncRequest:req wait:NO];
}

- (void)onClose
{
    //停止心跳
    [self stopLiveTimer];
    
    __weak typeof(self) ws = self;
    
    if (_isHost)
    {
        //通知业务服务器，退房
        ExitRoomRequest *exitReq = [[ExitRoomRequest alloc] initWithHandler:^(BaseRequest *request) {
            NSLog(@"上报退出房间成功");
        } failHandler:^(BaseRequest *request) {
            NSLog(@"上报退出房间失败");
        }];
        
        exitReq.token = [AppDelegate sharedAppDelegate].token;
        exitReq.roomnum = _liveItem.info.roomnum;
        exitReq.type = @"live";
        
        [[WebServiceEngine sharedEngine] asyncRequest:exitReq wait:NO];
    }
    else
    {
        [self reportMemberId:_liveItem.info.roomnum operate:1];
    }
    
    TILLiveManager *manager = [TILLiveManager getInstance];
    //退出房间
    [manager quitRoom:^{
        [ws.liveItem cleanLocalData];
        [ws.navigationController setNavigationBarHidden:NO animated:YES];
        [ws dismissViewControllerAnimated:YES completion:nil];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"exit room fail.module=%@,errid=%d,errmsg=%@",module,errId,errMsg);
        [ws.navigationController setNavigationBarHidden:NO animated:YES];
        [ws dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [[UserViewManager shareInstance] releaseManager];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kClickConnect_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCancelConnect_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserSwitchRoom_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kGroupDelete_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserParise_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPureDelete_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNoPureDelete_Notification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kEnterBackGround_Notification object:nil];
    
//    //停止网络环境心跳
//    [_envInfoTimer invalidate];
//    _envInfoTimer = nil;
}

#pragma mark - 心跳（房间保活）

//开始发送心跳
- (void)startLiveTimer
{
    [self stopLiveTimer];
    _heartTimer = [NSTimer scheduledTimerWithTimeInterval:kHeartInterval target:self selector:@selector(onPostHeartBeat:) userInfo:nil repeats:YES];
}

//发送心跳
- (void)onPostHeartBeat:(NSTimer *)timer
{
    HostHeartBeatRequest *heartReq = [[HostHeartBeatRequest alloc] initWithHandler:^(BaseRequest *request) {
        
        NSLog(@"---->heart beat succ");
    } failHandler:^(BaseRequest *request) {
        NSLog(@"---->heart beat fail");
    }];
    heartReq.token = [AppDelegate sharedAppDelegate].token;
    heartReq.roomnum = _liveItem.info.roomnum;
    heartReq.thumbup = _liveItem.info.thumbup;
    //判断自己是什么角色
    if (_isHost)
    {
        heartReq.role = 1;
    }
    else
    {
        BOOL isOpenCamear = [[ILiveRoomManager getInstance] getCurCameraState];
        
        if (isOpenCamear)//连麦用户
        {
            heartReq.role = 2;
        }
        else//普通观众
        {
            heartReq.role = 0;
        }
    }
    [[WebServiceEngine sharedEngine] asyncRequest:heartReq wait:NO];
    
    //每次心跳刷新一下成员列表，在随心播中，只显示了成员数
    [self onRefreshMemberList];
}

- (void)onRefreshMemberList
{
    __weak LiveViewController *ws = self;
    
    RoomMemListRequest *listReq = [[RoomMemListRequest alloc] initWithHandler:^(BaseRequest *request) {
        RoomMemListRspData *listRspData = (RoomMemListRspData *)request.response.data;
        [ws freshAudience:listRspData.idlist];
        
    } failHandler:^(BaseRequest *request) {
        NSLog(@"get group member fail ,code=%ld,msg=%@",(long)request.response.errorCode, request.response.errorInfo);
    }];
    listReq.token = [AppDelegate sharedAppDelegate].token;
    listReq.roomnum = _liveItem.info.roomnum;
    listReq.index = 0;
    listReq.size = 20;
    
    [[WebServiceEngine sharedEngine] asyncRequest:listReq wait:NO];
}

- (void)freshAudience:(NSArray *)memList
{
    _liveItem.info.memsize = (int)memList.count;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserMemChange_Notification object:nil];
}

//停止发送心跳
- (void)stopLiveTimer
{
    if(_heartTimer)
    {
        [_heartTimer invalidate];
        _heartTimer = nil;
    }
}

- (void)OnLocalVideoPreview:(QAVVideoFrame *)frameData
{
    //仅仅是为了打log
    NSString *key = frameData.identifier;
    if (key.length == 0)
    {
        key = [[ILiveLoginManager getInstance] getLoginId];
    }
    QAVFrameDesc *desc = [[QAVFrameDesc alloc] init];
    desc.width = frameData.frameDesc.width;
    desc.height = frameData.frameDesc.height;
    [_parView.resolutionDic setObject:desc forKey:key];
}

- (void)OnLocalVideoPreProcess:(QAVVideoFrame *)frameData
{
    //设置美颜、美白、红润等参数
    [self.preProcessor setOutputSize:CGSizeMake(frameData.frameDesc.width, frameData.frameDesc.height)];
    //开始预处理
    [self.preProcessor processFrame:frameData.data width:frameData.frameDesc.width height:frameData.frameDesc.height orientation:TXE_ROTATION_90 inputFormat:TXE_FRAME_FORMAT_NV12 outputFormat:TXE_FRAME_FORMAT_NV12];
    //将处理完的数据拷贝到原来的地址空间，如果是同步处理，此时会先执行（4）
    if(self.processorBytes)
    {
        memcpy(frameData.data, self.processorBytes, frameData.frameDesc.width * frameData.frameDesc.height * 3 / 2);
    }
}

- (void)OnVideoPreview:(QAVVideoFrame *)frameData
{
    //仅仅是为了打log
    NSString *key = frameData.identifier;
    QAVFrameDesc *desc = [[QAVFrameDesc alloc] init];
    desc.width = frameData.frameDesc.width;
    desc.height = frameData.frameDesc.height;
    [_parView.resolutionDic setObject:desc forKey:key];
}

- (void)didProcessFrame:(Byte *)bytes width:(NSInteger)width height:(NSInteger)height format:(TXEFrameFormat)format timeStamp:(UInt64)timeStamp
{
    self.processorBytes = bytes;
}

- (BOOL)onRoomDisconnect:(int)reason
{
    __weak typeof(self) ws = self;
    [AppDelegate showAlert:self title:@"房间失去连接" message:[@(reason) stringValue] okTitle:@"退出" cancelTitle:nil ok:^(UIAlertAction * _Nonnull action) {
        [ws onClose];
    } cancel:nil];
    return YES;
}
@end


