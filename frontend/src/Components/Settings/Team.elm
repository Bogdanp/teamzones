module Components.Settings.Team exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Types exposing (User)


type Msg
    = Submit


type alias Model =
    { teamMembers : List User }


init =
    Model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Submit ->
            model ! []


view : Model -> Html Msg
view { teamMembers } =
    let
        members =
            List.sortBy (.role >> toString) teamMembers
    in
        div []
            [ br [] []
            , table [ class "sm-ml" ]
                [ thead []
                    [ tr []
                        [ td [] [ text "Name" ]
                        , td [] [ text "Email" ]
                        , td [] [ text "Role" ]
                        , td [] []
                        ]
                    ]
                , tbody [] (List.map memberRow members)
                ]
            ]


memberRow : User -> Html Msg
memberRow { name, email, role } =
    tr []
        [ td [] [ text name ]
        , td [] [ text email ]
        , td [] [ text (toString role) ]
        , td [] []
        ]
