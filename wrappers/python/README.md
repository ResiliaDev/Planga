Planga Python Wrapper:
======================

**Setup:**

* Install Twine: `pip install twine`

**requirements:**

* [Python](https://www.python.org/) >= 2.7.x.
* [pip](http://www.pip-installer.org)
* virtualenv (Optional)

**Build and Deploy new package:**

* run `python3 setup.py sdist bdist_wheel`
* run `twine upload --repository-url https://test.pypi.org/legacy/ dist/* --skip-existing`

**Installing the new package:**

* run `python -m pip install jwcrypto`
* run `python -m pip install --index-url https://test.pypi.org/simple/ planga`

Installing jwcrypto manually is only necessary when uploading the planga wrapper to test.pypi.org. The installation tool will attempt to install jwcrypto from test.pypi.org as well, which fails. Having jwcrypto pre-installed allows the installation of the planga wrapper to finish successfully.

**Deploy to live Pypi:**

* run `twine upload dist/* --skip-existing`

For information on how to package for PiPy:
[https://packaging.python.org/tutorials/packaging-projects/](https://packaging.python.org/tutorials/packaging-projects/)

**Example usage:**

```python
from planga import *

conf = PlangaConfiguration("foobar", "kl9psH9VrLZ1hfsPY0b3-W", "general", "1234", "Bob", "my_container_div")

snippet = Planga.get_planga_snippet(conf)
```