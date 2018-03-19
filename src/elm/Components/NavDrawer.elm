module Components.NavDrawer exposing (..)

import Html exposing (..)
import Helpers.Style exposing (..)
import Html.Attributes exposing (..)
import Types exposing (..)


navDrawer : Model -> Html Msg
navDrawer model =
    nav [ classes [ "pa2", "fixed", "z-1", "bg-green-translucent", "top-4", showNavClass model.showNav ] ]
        [ drawerItem "./assets/Landing/menu-drawer/about_btn.svg" "#about"
        , drawerItem "./assets/Landing/menu-drawer/moodboard_btn.svg" "#moodboard"
        , drawerItem "./assets/Landing/menu-drawer/blog_btn.svg" "#blog"
        , drawerItem "./assets/Landing/menu-drawer/user_btn.svg" "#"
        , drawerItem "./assets/Landing/menu-drawer/emergency_btn.svg" "#"
        ]


drawerItem : String -> String -> Html Msg
drawerItem imgSrc hash =
    a [ classes [ "db", "pointer", "h4", "w4", "mb1" ], href hash, backgroundImageStyle imgSrc 100 ] []


showNavClass : Trilean -> String
showNavClass trilean =
    case trilean of
        Yes ->
            "enterNav"

        No ->
            "exitNav"

        Neutral ->
            "dn"