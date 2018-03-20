module Components.NavDrawer exposing (..)

import Html exposing (..)
import Helpers.Style exposing (..)
import Html.Events exposing (..)
import Types exposing (..)


navDrawer : Model -> Html Msg
navDrawer model =
    nav [ classes [ "pa2", "fixed", "z-1", "bg-green-translucent", "top-4", showNavClass model.showNav ] ]
        [ drawerItem "./assets/Landing/menu-drawer/about_btn.svg" About
        , drawerItem "./assets/Landing/menu-drawer/moodboard_btn.svg" Moodboard
        , drawerItem "./assets/Landing/menu-drawer/blog_btn.svg" Blog
        , drawerItem "./assets/Landing/menu-drawer/user_btn.svg" Landing
        , drawerItem "./assets/Landing/menu-drawer/emergency_btn.svg" Landing
        ]


drawerItem : String -> View -> Html Msg
drawerItem imgSrc view =
    button [ classes [ "db", "pointer", "h4", "w4", "mb1", "bn", "bg-transparent" ], onClick <| ChangeView view, backgroundImageStyle imgSrc 100 ] []


showNavClass : Trilean -> String
showNavClass trilean =
    case trilean of
        Yes ->
            "enterNav"

        No ->
            "exitNav"

        Neutral ->
            "dn"