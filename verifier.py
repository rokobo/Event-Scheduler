"""Provides verification related functions."""


def time_range(
        event: str, hour1: str, minutes1: int,
        hour2: int, minutes2: str, interval: str) -> list|bool:
    """
    Verifies if all values are valid.

    Args:
        event (str): Event name.
        hour1 (str): Start hour.
        minutes1 (int): Start minute.
        hour2 (int): End hour.
        minutes2 (str): End minute.
        interval (str): Repetition interval for the rule.

    Returns:
        list: Arguments given to this function.
        list: Arguments for the input fields.
        boolean: If the arguments are NOT valid.
    """
    value = (
        event is None,
        hour1 is None or hour1 > 23 or hour1 < 0,
        minutes1 is None or minutes1 > 59 or minutes1 < 0,
        hour2 is None or hour2 > 23 or hour2 < 0,
        minutes2 is None or minutes2 > 59 or minutes2 < 0,
        interval is None
    )

    arguments = (event, hour1, minutes1, hour2, minutes2, interval)
    false = (False, False, False, False, False, False)
    none = (None, None, None, None, None, None)
    not_valid = True in value

    if not_valid:  # checks for invalid arguments
        if not all(v for v in value):  # checks for empty input
            return_value = value + arguments
        else:
            return_value = false + arguments
    else:
        return_value = false + none
    return arguments, return_value, not_valid
