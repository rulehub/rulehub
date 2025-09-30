import textwrap

from tools.enforce_no_generic_only_tests import extract_json_like


def test_extract_json_like_parses_trailing_commas_single_line():
    obj_str = '{"controls": {"policy": false}, "cookies": {"a": true}, }'
    parsed = extract_json_like(obj_str)
    assert isinstance(parsed, dict)
    assert parsed["controls"]["policy"] is False
    assert parsed["cookies"]["a"] is True


def test_extract_json_like_parses_multiline_with_trailing_commas():
    obj_str = textwrap.dedent(
        """
        {
          "controls": {"policy": false},
          "cookies": {
            "non_essential_set_before_consent": true,
          },
        }
        """
    )
    parsed = extract_json_like(obj_str)
    assert isinstance(parsed, dict)
    assert parsed["controls"]["policy"] is False
    assert parsed["cookies"]["non_essential_set_before_consent"] is True
