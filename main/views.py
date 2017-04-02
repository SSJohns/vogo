from django.shortcuts import render
from django.template import loader
from django.views.generic import View
from django.http import HttpResponse
from .models import BoolQuestion, BoolResponse, MCQuestion, MCOption, MCResponse

import os
import subprocess
import random
import html

def render_elm(request, html_template, html_context, elm_template, elm_context):
  """ Renders elm context into an elm file, calls `elm-make` on that elm file, and
      adds the compiled javascript into the context of the html file
  """
  session_key = random.randint(1000000, 10000000)
  js_filename = 'elm-build/temp' + str(session_key) + '.js'
  elm_filename = 'elm-build/temp' + str(session_key) + '.elm'

  # Render the elm
  rendered_elm = loader.render_to_string(elm_template, elm_context, request)

  # Output the rendered elm to a temporary file
  with open(elm_filename, 'w+') as elm_with_context_file:
    elm_with_context_file.write(rendered_elm)

  # Call elm-make on the rendered file
  # TODO: Only debug is settings.debug
  return_code = subprocess.call("elm-make " + elm_filename + " --debug --output " + js_filename, shell=True)

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
  def get_vals(self):
    y = "["
    for x in BoolQuestion.objects.all().order_by('id'):
        # Starting as Neutral but need to check
        # if user has voted before
        y += " Voting <| VotingQuestion \"%s\" \"%s\" %d \"%s\" Neutral" % (x.title, x.prompt, x.score, x.id)
        y += "\n"
        y += ","
    for x in MCQuestion.objects.all():
        y += "MC <| MultipleChoiceQuestion \"%s\" \"%s\" \"%s\" MultipleChoiceOption " % (x.id, x.title, x.prompt, )
        for z in [MCOption.objects.get(question_id=x.id)]:
            y += "%s " % z.option
        y += "\n"
        y += ","
    y += "]"
    print(html.unescape(y))
    self.y = html.unescape(y)


  def get(self, request):
    #self.get_vals()
    voting_questions = BoolQuestion.objects.all()
    elm_flags = {
      'score': 42,
      'name': "8 bit 1 byte",
      'voting_questions': voting_questions
    }
    context = {
      #'elm_flags': elm_flags,
      'static_file': 'js/home.js'
    }
    # return render(request, 'elm.html', context)
    return render_elm(request, 'elm.html', context, 'home.elm', elm_flags)
