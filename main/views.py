from django.shortcuts import render
from django.template import loader
from django.views.generic import View
from django.http import HttpResponse

import os
import subprocess
import random

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
  return_code = subprocess.call("elm-make " + elm_filename + " --output " + js_filename, shell=True)

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
  def get(self, request):
    elm_flags = {
      'score': 42,
      'name': "8 bit 1 byte"
    }
    context = {
      #'elm_flags': elm_flags,
      'static_file': 'js/home.js'
    }
    return render(request, 'elm.html', context)
    #return render_elm(request, 'elm.html', context, 'home.elm', elm_flags)
