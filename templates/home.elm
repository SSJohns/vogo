module TestModule exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode

main =
  Html.program
    { init = init ! []
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { score : Int
  , name : String
  , questions : List Question
  }

type Question
  = Voting VotingQuestion
  | MC MultipleChoiceQuestion

type alias VotingQuestion =
  { title : String
  , prompt : String
  , score : Int
  , uuid : String
  , userStatus : Status
  }

type alias MultipleChoiceQuestion =
  { uuid : String
  , title : String
  , prompt : String
  , answers : List MultipleChoiceOption
  }

type alias MultipleChoiceOption =
  { option : String
  , uuid : String
  , selected : Bool
  }

mc_question : MultipleChoiceQuestion
mc_question =
  MultipleChoiceQuestion "0xyz" "What dinner?" "What want." options

options : List MultipleChoiceOption
options =
  [ MultipleChoiceOption "Steak" "1234" False
  , MultipleChoiceOption "Burger" "1235" False
  , MultipleChoiceOption "Salmon" "1236" False
  , MultipleChoiceOption "Chipotle" "1237" False
  ]

type Status
  = Upvoted
  | Downvoted
  | Neutral

init : Model
init =
  Model {{ score }} "{{ name }}" questions

-- UPDATE

type Msg
  = Noop
  | Upvote VotingQuestion
  | Downvote VotingQuestion

increaseScore : VotingQuestion -> VotingQuestion
increaseScore question =
  { question | score = question.score + 1 }

decreaseScore : VotingQuestion -> VotingQuestion
decreaseScore question =
  { question | score = question.score - 1 }

setStatus : Status -> VotingQuestion -> VotingQuestion
setStatus newStatus question =
  { question | userStatus = newStatus }

undoExistingVote : VotingQuestion -> VotingQuestion
undoExistingVote question =
  case question.userStatus of
    Upvoted ->
      question
        |> decreaseScore
        |> setStatus Neutral
    Downvoted ->
      question
        |> increaseScore
        |> setStatus Neutral
    Neutral ->
      question


updateQuestion : Status -> VotingQuestion -> VotingQuestion
updateQuestion newStatus question =
  case newStatus of
    Upvoted ->
      question
        |> undoExistingVote
        |> increaseScore
        |> setStatus Upvoted
    Downvoted ->
      question
        |> undoExistingVote
        |> decreaseScore
        |> setStatus Downvoted
    _ ->
      question
        |> setStatus Neutral

updateQuestions : List Question -> String -> Status -> List Question
updateQuestions questions id newStatus =
  case questions of
    [] ->
      []
    first :: rest ->
      case first of
        Voting votingQ ->
          if votingQ.uuid == id then
            (Voting <| updateQuestion newStatus votingQ) :: updateQuestions rest id newStatus
          else
            (Voting votingQ) :: updateQuestions rest id newStatus
        MC mcQ ->
          (MC mcQ) :: updateQuestions rest id newStatus

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Noop ->
      model ! []

    Upvote question ->
      { model | questions = (updateQuestions model.questions question.uuid Upvoted) }
        ! []

    Downvote question ->
      { model | questions = (updateQuestions model.questions question.uuid) Downvoted}
        ! []

-- VIEW

upvoteButton : VotingQuestion -> Html Msg
upvoteButton question =
  case question.userStatus of
    Upvoted ->
      button [ onClick <| Upvote question, class "disabled btn cyan lighten-3 waves-effect waves-light" ] [icon "arrow_drop_up"]

    _ ->
      button [ onClick <| Upvote question, class "btn cyan lighten-3 waves-effect waves-light" ] [icon "arrow_drop_up"]

downvoteButton : VotingQuestion -> Html Msg
downvoteButton question =
  case question.userStatus of
    Downvoted ->
      button [ onClick <| Downvote question, class "disabled btn cyan lighten-3 waves-effect waves-light" ] [icon "arrow_drop_down"]

    _ ->
      button [ onClick <| Downvote question, class "btn cyan lighten-3 waves-effect waves-light" ] [icon "arrow_drop_down"]

card : VotingQuestion -> Html Msg
card question =
  div [ class "row" ]
    [ div [ class "col s10 offset-s1" ]
      [ div [ class "card-panel cyan lighten-1 row" ]
        [ div [ class "col s9 m10" ]
          [ h4 [ class "white-text thin" ] [ text question.title ]
          , span [ class "white-text" ] [ text question.prompt ]
          ]
        , div [ class "col s3 m2 white-text center" ]
          [ upvoteButton question
          , h4 [ class "thin" ] [ text <| toString question.score ]
          , downvoteButton question
          ]
        ]
      ]     
    ]

icon : String -> Html Msg
icon name =
  i [ class "material-icons" ] [ text name ]

createButton : Html Msg
createButton =
  div [ class "fixed-action-btn" ]
    [ button [ class "btn-floating btn-large waves-effect waves-light cyan lighten-3" ]
      [ icon "add"
      ]
    ]

navbar : Html Msg
navbar =
  div [ class "navbar-fixed" ]
    [ nav []
      [ div [ class "nav-wrapper cyan lighten-3" ]
        [ a [ class "brand-logo center" ] [ text "Vogo" ]
        ]
      ]
    ]

questions : List Question
questions =
  [ Voting <| VotingQuestion "Title of Q" "lorem ipsum dolor sit amet" 0 "1" Neutral
  , MC <| mc_question
  , Voting <| VotingQuestion "Title of Q" "lorem ipsum dolor sit amet" 0 "2" Neutral
  , MC <| mc_question
  , Voting <| VotingQuestion "Title of Q" "lorem ipsum dolor sit amet" 0 "3" Neutral
  ]

mcOption : MultipleChoiceOption -> Html Msg
mcOption option =
  p []
    [ input [ name "group1", type_ "radio", id option.uuid ] []
    , label [ class "white-text", for option.uuid ] [ text option.option ]
    ]

mcQuestion : MultipleChoiceQuestion -> Html Msg
mcQuestion question =
  div [ class "row" ]
    [ div [ class "col s10 offset-s1" ]
      [ div [ class "card-panel cyan lighten-1 row" ]
        [ h4 [ class "white-text thin" ] [ text question.title ]
        , span [ class "white-text" ] [ text question.prompt ]
        , div [] (List.map mcOption question.answers)
        ]
      ]
    ]

questionView : Question -> Html Msg
questionView question =
  case question of
    Voting votingQ ->
      card votingQ

    MC mcQ ->
      mcQuestion mcQ

view : Model -> Html Msg
view model =
  div [ class "cyan lighten-5" ]
    [ navbar
    , createButton
    , div [] (List.map questionView model.questions)
    {--
    , mcQuestion mc_question
    , h2 [] [text <| toString model.score]
    , h2 [] [text model.name]
    , h2 [] [text "YAY!"]
    , div [] (List.map card model.questions)
    --}
    ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
