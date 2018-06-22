module Components.ScreenOverlay
    exposing
        ( ScreenOverlay
        , hide
        , initOverlay
        , isOverlayVisible
        , noXOverlayView
        , overlayView
        , show
        , withOverlayStyles
        )

import Css exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attrs
import Html.Styled.Events exposing (onClick)
import Ports


-- ******
-- Styling
-- ******


overlayStyle : Bool -> Style
overlayStyle displaying =
    batch
        [ position fixed
        , padding4 (Css.rem 8) (Css.rem 10) (Css.rem 1) (Css.rem 4)
        , top zero
        , left zero
        , zIndex (int -4)
        , width (vw 100)
        , height (vh 100)
        , backgroundColor (Css.rgba 255 255 255 0)
        , overflowX auto
        , property "pointer-events" "none"
        , property "transition" "background-color 500ms ease 250ms, z-index 0ms 750ms"
        , if displaying then
            batch
                [ backgroundColor (rgba 255 255 255 1)
                , property "pointer-events" "auto"
                , zIndex (int 4)
                , property "transition" "background-color 500ms ease, z-index 0ms 0ms"
                ]
          else
            batch []
        ]


exitButtonStyle : Bool -> Style
exitButtonStyle onScreen =
    batch
        [ border zero
        , backgroundColor transparent
        , right (Css.rem -4)
        , zIndex (int 1)
        , Css.focus
            [ backgroundColor transparent ]
        , position fixed
        , property "transition" "right 200ms ease-in, transform 200ms ease-in"
        , Css.hover [ textShadow4 (px -1) (px -2) (px 3) (rgba 0 0 0 0.3) ]
        , if onScreen then
            batch
                [ right (Css.rem 4)
                , transform (rotate (deg -180))
                , property "transition" "right 200ms ease-out 255ms, transform 200ms ease-out 255ms"
                ]
          else
            batch []
        ]


contentStyle : Bool -> Style
contentStyle onScreen =
    batch
        [ marginTop (Css.rem 4)
        , position relative
        , left (pct -200)
        , property "transition" "left 250ms ease-in"
        , if onScreen then
            batch
                [ left zero
                , property "transition" "left 255ms ease-out 225ms"
                ]
          else
            batch []
        ]



-- ****
-- Data
-- ****


{-| Returns whether the overlay is visible or not
-}
isOverlayVisible : ScreenOverlay -> Bool
isOverlayVisible (ScreenOverlay state _) =
    isVisible state


type ScreenState
    = Visible
    | NonVisible


isVisible : ScreenState -> Bool
isVisible state =
    case state of
        Visible ->
            True

        NonVisible ->
            False


type alias StyleOverride =
    Maybe (List Style)


extractOverrideStyles : StyleOverride -> List Style
extractOverrideStyles override =
    case override of
        Nothing ->
            []

        Just styles ->
            styles


{-| An opaque type to store in the model that represents the overlay state and html content
-}
type ScreenOverlay
    = ScreenOverlay ScreenState StyleOverride


{-| Create a ScreenOverlay with no html content
-}
initOverlay : ScreenOverlay
initOverlay =
    ScreenOverlay NonVisible Nothing


{-| Update a ScreenOverlay with styles to override the default styling
-}
withOverlayStyles : List Css.Style -> ScreenOverlay -> ScreenOverlay
withOverlayStyles styles (ScreenOverlay visibility _) =
    ScreenOverlay visibility (Just styles)


{-| Make the overlay screen visible
-}
show : ScreenOverlay -> ( ScreenOverlay, Cmd msg )
show (ScreenOverlay _ styles) =
    ( ScreenOverlay Visible styles, Ports.send Ports.OverlayLock )


{-| Make the overlay screen hidden
-}
hide : ScreenOverlay -> ( ScreenOverlay, Cmd msg )
hide (ScreenOverlay _ styles) =
    ( ScreenOverlay NonVisible styles, Ports.send Ports.OverlayLockRelease )



-- ****
-- View
-- ****


{-| Add this to the view to add the overlay screen content to the dom
-}
overlayView : ScreenOverlay -> msg -> Html msg -> Html msg
overlayView overlay closeMsg markup =
    commonView overlay (Just closeMsg) markup


{-| Add this to the view to add the overlay screen (without the (X) - close button)
-}
noXOverlayView : ScreenOverlay -> Html msg -> Html msg
noXOverlayView overlay markup =
    commonView overlay Nothing markup


commonView : ScreenOverlay -> Maybe msg -> Html msg -> Html msg
commonView (ScreenOverlay visibility styles) close markup =
    div
        [ Attrs.css [ overlayStyle (isVisible visibility) ]
        , extractOverrideStyles styles
            |> Attrs.css
        , Attrs.class "overlay-content"
        ]
        [ close
            |> Maybe.map (exitButton visibility)
            |> Maybe.withDefault (text "")
        , div
            [ Attrs.class "content"
            , Attrs.css [ contentStyle (isVisible visibility) ]
            ]
            [ markup ]
        ]


exitButton : ScreenState -> msg -> Html msg
exitButton visibility closeMsg =
    button
        [ Attrs.class "exit-button"
        , onClick closeMsg
        , Attrs.css [ exitButtonStyle (isVisible visibility) ]
        ]
        [ span
            [ Attrs.class "material-icons"
            , Attrs.css [ fontSize (Css.rem 4) ]
            ]
            [ text "close" ]
        ]
