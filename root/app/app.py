from flask import (
    Flask,
    request,
    render_template,
    make_response,
    redirect,
)
import os
import mimetypes

mimetypes.add_type('text/xsl', '.xsl')

PATH = os.path.abspath(os.path.dirname(__file__))

config = {
    'static_url_path': ''
}

app = Flask(__name__, **config)


def is_mobile():
    user_agent = request.headers.get('User-Agent')
    mobile_trigger = ['Android', 'iPhone', 'Windows Phone', 'Mobile']
    return any(x in user_agent for x in mobile_trigger)


def should_return_svg():
    best_mimetype = request.accept_mimetypes.best_match(['image/svg+xml', 'text/html'])
    if best_mimetype == 'image/svg+xml':
        return True
    return False


def _make_response_factory(content_type):
    def inner_func(template_name, result={}, defaults={}):
        variables = defaults.copy()
        variables.update(result)
        response = make_response(render_template(template_name, **variables))
        response.headers['Content-Type'] = content_type
        return response

    return inner_func


make_svg_response = _make_response_factory('image/svg+xml')
make_xhtml_response = _make_response_factory('application/xhtml+xml')


@app.route('/index.svg')
def page_top_svg():
    menu = enumerate([
        ('Works', '/works/', '/img/icons/file.svg'),
        ('Blog', 'http://cocu.hatenablog.com/', '/img/icons/hatenablog-logo-white.svg'),
        ('Link', '/link/', '/img/icons/link.svg'),
        ('About', '/about/', '/img/icons/about.svg')
    ])
    params = {
        'nav_width': 400,
        'nav_line_height': 65,
        'menu': menu,
    }
    return make_svg_response('top.svg.jinja2', params)


@app.route('/')
def page_top():
    svg_file = 'index.svg'
    if should_return_svg():
        return page_top_svg()
    return make_xhtml_response('top.jinja2', {'svg_file': svg_file})


@app.route('/works/')
def page_works():
    return make_xhtml_response('works.jinja2')


@app.route('/link/')
def page_link():
    return make_xhtml_response('link.jinja2')


@app.route('/about/')
def page_about():
    return make_xhtml_response('about.jinja2')


@app.route('/i_love_svg')
def i_love_svg():
    res = redirect('/index.svg')
    return res


@app.route('/i_love_xhtml')
def i_love_xhtml():
    res = redirect('/')
    return res


@app.errorhandler(403)
@app.errorhandler(404)
def error_page(e):
    return make_xhtml_response('error.jinja2', {'error_code': "404 NotFound"}), 404


if __name__ == '__main__':
    app.run('127.0.0.1', 8000,debug=True)
