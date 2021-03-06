module State exposing (..)

import Data.Avatar exposing (avatarSrcToAvatar)
import Data.Database exposing (dbDataToModel)
import Data.Hotspots exposing (..)
import Data.SkinColour exposing (hexValueToSkinColour, skinColourToHexValue, toggleSkinColour)
import Data.Stim exposing (addBodypart, addExerciseName, addHowTo, addNewStimVideo, closeActionButtons, defaultStim, deleteStimFromModel, generateRandomStim, hideVideos, normaliseStim, toggleActionButtons, toggleSharedStim, toggleStimVideo, updateShowVideo, updateStimInModel)
import Data.Time exposing (adjustTime, trackCounter)
import Data.User exposing (normaliseUser)
import Data.View exposing (..)
import Delay exposing (..)
import Helpers.Utils exposing (ifThenElse, sanitiseAvatarName, scrollToTop, stringToFloat)
import Ports exposing (..)
import Random
import Requests.GetVideos exposing (getVideos)
import Time exposing (..)
import Transit
import Types exposing (..)
import Update.Extra.Infix exposing ((:>))


initModel : Model
initModel =
    { view = Splash
    , userId = ""
    , avatar = Avatar1
    , avatarName = ""
    , skinColour = SkinColour7
    , stims = []
    , newStim = defaultStim
    , counter = 0
    , timeSelected = 0
    , svgClockTime = 0
    , timerStatus = Stopped
    , vidSearchString = ""
    , videos = []
    , videoStatus = NotAsked
    , showNav = Neutral
    , stimMenuShowing = Nothing
    , hotspots = defaultHotspots
    , selectedStim = defaultStim
    , transition = Transit.empty
    , stimsWithUser = []
    , stimInfoDestination = Landing
    , lastOnboarding = False
    }


init : ( Model, Cmd Msg )
init =
    initModel ! [ initDB (), fetchFirebaseStims () ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeView nextView ->
            let
                previousView =
                    model.view
            in
                { model
                    | view = nextView
                    , stimMenuShowing = Nothing
                    , showNav = Neutral
                    , lastOnboarding = False
                    , hotspots = ifThenElse (nextView == CreateAvatar) initModel.hotspots model.hotspots
                    , skinColour = ifThenElse (nextView == CreateAvatar) initModel.skinColour model.skinColour
                    , avatar = ifThenElse (nextView == CreateAvatar) initModel.avatar model.avatar
                    , stimsWithUser = ifThenElse (nextView == Blog) (hideVideos model.stimsWithUser) model.stimsWithUser
                    , counter = ifThenElse (nextView == TimerPreparation) (initModel.counter) model.counter
                    , timeSelected = ifThenElse (nextView == TimerPreparation) (initModel.timeSelected) model.timeSelected
                    , timerStatus = ifThenElse (previousView == Timer) (initModel.timerStatus) model.timerStatus
                    , stimInfoDestination = ifThenElse (previousView == Timer) Timer (initModel.stimInfoDestination)
                    , svgClockTime = model.counter
                }
                    ! (scrollToTop :: viewToCmds nextView model)

        ReceiveHotspotCoords (Ok coords) ->
            { model | hotspots = coords } ! []

        ReceiveHotspotCoords (Err err) ->
            model ! []

        UpdateVideoSearch string ->
            { model | vidSearchString = string }
                ! []

        CallVideoRequest ->
            { model | videoStatus = Loading, videos = [] } ! [ getVideos model, videoCarousel () ]

        ReceiveVideos (Ok list) ->
            { model | videoStatus = ResponseSuccess, videos = list } ! [ videoCarousel () ]

        ReceiveVideos (Err string) ->
            { model | videoStatus = ResponseFailure } ! []

        ToggleNav ->
            { model | showNav = updateNav model.showNav, stimMenuShowing = Nothing } ! []

        ToggleStimMenu bodyPart ->
            { model
                | stimMenuShowing = updateStimMenu model bodyPart
                , showNav = hideNav model.showNav
                , newStim = addBodypart bodyPart model.newStim
                , stims = closeActionButtons model.stims
            }
                ! []

        NoOp ->
            model ! []

        SaveStim stim ->
            { model | videos = initModel.videos }
                ! [ saveStim <| normaliseStim stim ]
                :> update (NavigateTo Landing)

        SetTime time ->
            let
                interval =
                    stringToFloat time
            in
                { model | timeSelected = interval, counter = interval } ! []

        SetTimeFromText time ->
            let
                interval =
                    if stringToFloat time > 10 then
                        10
                    else if stringToFloat time < 0 then
                        0
                    else
                        stringToFloat time
            in
                { model | timeSelected = interval * 60, counter = interval * 60 } ! []

        Tick _ ->
            trackCounter model
                ! []
                :> update
                    (ifThenElse (model.counter <= 0 && model.view == Timer)
                        (NavigateTo StimFinish)
                        (NoOp)
                    )

        AdjustTimer timerControl ->
            adjustTime timerControl model ! []

        TransitMsg a ->
            Transit.tick TransitMsg a model

        NavigateTo view ->
            Transit.start TransitMsg (ChangeView view) ( 200, 200 ) model

        StopTimer ->
            model
                ! []
                :> update (AdjustTimer Stop)
                :> update (NavigateTo StimFinish)

        SaveOrUpdateUser ->
            model ! [ saveOrUpdateUser <| normaliseUser model ]

        ToggleBodypart bodypart ->
            { model | newStim = addBodypart bodypart model.newStim } ! []

        AddExerciseName string ->
            { model | newStim = addExerciseName string model.newStim } ! []

        AddHowTo string ->
            { model | newStim = addHowTo string model.newStim } ! []

        ReceiveInitialData (Ok dbData) ->
            dbDataToModel dbData model ! [ navigateFromSplash dbData.user.userId ]

        ReceiveInitialData (Err err) ->
            model ! [ navigateFromSplash "" ]

        ReceiveStimList (Ok listStims) ->
            { model | stims = listStims } ! []

        ReceiveUserSaveSuccess bool ->
            model
                ! []
                :> update (NavigateTo Landing)

        ReceiveStimList (Err err) ->
            model ! []

        ReceiveFirebaseStims (Ok listStims) ->
            { model | stimsWithUser = listStims } ! []

        ReceiveFirebaseStims (Err err) ->
            model ! []

        UpdateNewStimVideo videoId ->
            let
                newModel =
                    { model | newStim = addNewStimVideo videoId model }
            in
                newModel
                    ! []

        GoToStim stim ->
            { model | selectedStim = stim }
                ! []
                :> update (NavigateTo StimInfo)

        AddAvatarName name ->
            { model | avatarName = sanitiseAvatarName name }
                ! []

        GoToRandomStim ->
            model
                ! [ Random.generate GoToStim (generateRandomStim model)
                  ]

        ShareStim stim ->
            updateStimInModel model stim
                ! [ shareStim <| ( normaliseStim stim, normaliseUser model ), fetchFirebaseStims (), Delay.after 1000 millisecond (NavigateTo Landing) ]

        ImportStim stim ->
            model
                ! [ saveStim <| normaliseStim stim ]

        ChangeSkinColour ->
            { model | skinColour = toggleSkinColour model } ! [ changeSkinColour ( toggleSkinColour model |> skinColourToHexValue, ".is-selected" ) ]

        KeyDown string key ->
            ifThenElse (key == 13)
                ({ model | vidSearchString = string }
                    ! []
                    :> update CallVideoRequest
                )
                (model ! [])

        KeyDownFromName key ->
            ifThenElse (key == 13)
                (model
                    ! []
                    :> update (NavigateTo Landing)
                )
                (model
                    ! []
                )

        ReceiveLastOnboarding bool ->
            { model | lastOnboarding = bool } ! []

        NavigateToShareModal stim ->
            { model | selectedStim = stim }
                ! []
                :> update (NavigateTo ShareModal)

        NavigateToDeleteModal stim ->
            { model | selectedStim = stim }
                ! []
                :> update (NavigateTo DeleteModal)

        ToggleActionButtons stim ->
            { model | stims = toggleActionButtons stim model.stims } ! []

        DeleteStim stim ->
            { model | stims = deleteStimFromModel stim model.stims } ! [ deleteStim stim.stimId, Delay.after 1000 millisecond (NavigateTo Landing) ]

        ReceiveDeleteStimSuccess bool ->
            model ! []

        UpdateAvatar { src, skinColour } ->
            { model
                | skinColour = hexValueToSkinColour skinColour
                , avatar = avatarSrcToAvatar src
            }
                ! []

        ShowVideo stim ->
            { model | stimsWithUser = toggleStimVideo stim model.stimsWithUser } ! []
