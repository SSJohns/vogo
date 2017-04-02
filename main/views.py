from django.shortcuts import render
from django.template import loader
from django.views.generic import View
from django.http import HttpResponse, JsonResponse
from django.conf import settings
from django.middleware.csrf import get_token

from .models import BoolQuestion, BoolResponse, MCQuestion, MCOption, MCResponse

import os
import subprocess
import random
import json

def render_elm(request, html_template, html_context, elm_template, elm_context):
  """ Renders elm context into an elm file, calls `elm-make` on that elm file, and
      adds the compiled javascript into the context of the html file
  """
  if not request.session.session_key:
    request.session.save()
  session_key = request.session.session_key
  js_filename = 'elm-build/temp' + str(session_key) + '.js'
  elm_filename = 'elm-build/temp' + str(session_key) + '.elm'

  # Render the elm
  rendered_elm = loader.render_to_string(elm_template, elm_context, request)
  print(rendered_elm)

  # Output the rendered elm to a temporary file
  with open(elm_filename, 'w+') as elm_with_context_file:
    elm_with_context_file.write(rendered_elm)

  # Call elm-make on the rendered file
  # TODO: Only debug is settings.debug
  command_string = "elm-make " + elm_filename + " --yes --output " + js_filename
  if settings.DEBUG:
    command_string += " --debug"
  return_code = subprocess.call(command_string, shell=True)

  # Exit if failed to build
  if return_code != 0:
    os.remove(elm_filename)
    return HttpResponse("Failed to build elm")

  # Read the output of elm-make into a string
  with open(js_filename) as compiled_javascript_file:
    compiled_javascript = compiled_javascript_file.read()

  # Delete
  os.remove(elm_filename)
  os.remove(js_filename)

  html_context['elm_js'] = compiled_javascript

  return render(request, html_template, html_context)


# Create your views here.
class HomeView(View):
  def post(self, request):
    if not request.session.session_key:
      request.session.save()
    session_key = request.session.session_key
    print(session_key)

    request_params = json.loads(request.body)
    question_id = request_params["question_id"]
    question = BoolQuestion.objects.get(id=question_id)

    response, created = BoolResponse.objects.get_or_create(
        question_id=question,
        session_key_of_creator=session_key
    )
    response.vote_resp = request_params["should_upvote"]
    response.save()

    return JsonResponse({
      "message": "Upvoted"
    })

  def get(self, request):
    if not request.session.session_key:
      request.session.save()
    session_key = request.session.session_key
    print(session_key)

    # Internal class for making templates nicer
    class VotingQuestion():
      def __init__(self, voting_question):
        self.question = voting_question
        self.title = self.question.title
        self.prompt = self.question.prompt
        self.lat = self.question.lat
        self.lon = self.question.lon
        self.radius = self.question.radius
        self.id = self.question.id
        self.responses = self.question.responses

        self.score = 0
        for response in BoolResponse.objects.filter(question_id=self.question):
          if response.vote_resp:
            self.score += 1
          else:
            self.score -= 1

        user_response = BoolResponse.objects.filter(
          session_key_of_creator=session_key,
          question_id=self.question
        )

        self.user_vote = "Neutral"
        if user_response:
          if user_response.first().vote_resp:
            self.user_vote = "Upvoted"
          else:
            self.user_vote = "Downvoted"
        
    mc_questions = MCQuestion.objects.all()
    bool_questions = BoolQuestion.objects.all()

    elm_flags = {
      'voting_questions': [VotingQuestion(bool_q) for bool_q in bool_questions],
      'mc_questions': mc_questions,
      'csrf': get_token(request),
    }
    context = {
      'static_file': 'js/home.js'
    }
    return render_elm(request, 'elm.html', context, 'home.elm', elm_flags)
