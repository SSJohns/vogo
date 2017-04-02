module TestModule exposing (..)

import Geolocation exposing (Location)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Task
import Json.Decode as Decode
import Json.Encode as Encode

main =
  Html.program
    { init = (init, Task.attempt Update Geolocation.now)
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model =
  { score : Int
  , name : String
  , questions : List Question
  , userLocation : Result Geolocation.Error (Maybe Location)
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
  , location : SimpleLocation
  , radius : Float
  }

type alias MultipleChoiceQuestion =
  { uuid : String
  , title : String
  , prompt : String
  , answers : List MultipleChoiceOption
  , location : SimpleLocation
  , radius : Float
  }

type alias MultipleChoiceOption =
  { option : String
  , uuid : String
  , selected : Bool
  }

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
  Model 0 "" questions (Ok Nothing)

-- UPDATE

type Msg
  = Upvote VotingQuestion
  | Downvote VotingQuestion
  | Update (Result Geolocation.Error Location)
  | ReceiveResponse (Result Http.Error String)

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

type alias SimpleLocation =
  { lat : Float
  , lon : Float
  }

distanceBetween : SimpleLocation -> SimpleLocation -> Float
distanceBetween start end =
  let
    dlat = end.lat - start.lat
    dlng = end.lon - start.lon
  in
    ( sqrt ((dlat * dlat) + (dlng * dlng)) ) * 111319.5

getQuestionLoc : Question -> SimpleLocation
getQuestionLoc question = 
  case question of
    Voting q ->
      q.location
    MC q ->
      q.location

getQuestionRadius : Question -> Float
getQuestionRadius question = 
  case question of
    Voting q ->
      q.radius
    MC q ->
      q.radius

filterByRadius : (Result Geolocation.Error (Maybe Location)) -> Question -> Bool
filterByRadius userLocation question =
  case userLocation of
    Ok (Just location) ->
      (distanceBetween { lat=location.latitude, lon=location.longitude } (getQuestionLoc question)) < (getQuestionRadius question)

    _ ->
      False

compareDistancesTo : (Result Geolocation.Error (Maybe Location)) -> Question -> Question -> Basics.Order
compareDistancesTo userLocation a b =
  case userLocation of
    Ok (Just location) ->
      let
        distanceFromStart = distanceBetween { lat=location.latitude, lon=location.longitude }
      in
        compare (distanceFromStart <| getQuestionLoc a) (distanceFromStart <| getQuestionLoc b)
    _ ->
      EQ

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
    Upvote question ->
      { model | questions = (updateQuestions model.questions question.uuid Upvoted) }
        ! [makeRequest <| upvoteRequest question]

    Downvote question ->
      { model | questions = (updateQuestions model.questions question.uuid) Downvoted}
        ! [makeRequest <| downvoteRequest question]

    Update result ->
      { model | userLocation = Result.map Just result } ! []

    ReceiveResponse _ ->
      model ! []
    {--
    ReceiveResponse (Ok response) ->
      model ! []

    ReceiveResponse (Err err) ->
      model
        |> setResult (toString err)
        |> markResultAsError
        |> endLoading
    --}

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
  div [] 
    [ div [ class "fixed-action-btn" ]
      [ a [ href "#modal1", class "modal-trigger btn-floating btn-large waves-effect waves-light cyan lighten-3"]
        [ icon "add" ]
        ]
    , div [ id "modal1", class "modal modal-fixed-footer" ]
      [ div [ class "modal-content" ]
        [ div [ class "row" ]
          [ div [class "input-field col s6" ]
            [ input [ id "firstname", type_ "text", attribute "data-length" "25" ] []
            , label [for "firstname"] [ text "Title" ]
            ]
          ]
        , div [ class "row"]
          [ div [class "input-field col s12"]
            [ textarea [ id "textarea1", class "materialize-textarea", attribute "data-length" "300"] []
            , label [for "textarea1"] [text "Enter description (optional)"]
            ]
          ]
        ]
      , div [ class "modal-footer" ] 
        [ button [class "btn waves-effect waves-light", type_ "submit", name "action"][text "Submit"]
        ]
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
  [
  {% for question in voting_questions %}
    Voting <| VotingQuestion "{{ question.title }}" "{{ question.prompt }}" {{ question.score }} "{{ question.id }}" {{ question.user_vote }} (SimpleLocation {{ question.lat }} {{ question.lon }}) {{ question.radius }},
  {% endfor %}
  {% for question in mc_questions %}
    MC <| MultipleChoiceQuestion "{{ question.id }}" "{{ question.title }}" "{{ question.prompt }}" 
      [
      {% for option in question.possibleAnswers %}
        MultipleChoiceOption "{{ option.option | safe }}" "{{ option.id }}" False
        {% if not forloop.last %}
        ,
        {% endif %}
      {% endfor %}
      ] (SimpleLocation {{ question.lat }} {{ question.lon }}) {{ question.radius }}
    {% if not forloop.last %}
    ,
    {% endif %}
  {% endfor %}
  --for option in mc_options?
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
    , div []
      ( model.questions
        |> List.filter (filterByRadius model.userLocation)
        |> List.sortWith (compareDistancesTo model.userLocation)
        |> List.map questionView
      )
    ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Geolocation.changes (Update << Ok)

-- Effects

upvoteRequest : VotingQuestion -> Http.Body
upvoteRequest question =
  Http.jsonBody <| Encode.object 
    [ ("question_id", Encode.string question.uuid)
    , ("should_upvote", Encode.bool True)
    ]

downvoteRequest : VotingQuestion -> Http.Body
downvoteRequest question =
  Http.jsonBody <| Encode.object 
    [ ("question_id", Encode.string question.uuid)
    , ("should_upvote", Encode.bool False)
    ]

makeRequest : Http.Body -> Cmd Msg
makeRequest json =
  Http.send ReceiveResponse (Http.post "" json decoder)

decoder : Decode.Decoder String
decoder =
  Decode.at ["message"] Decode.string
