#include "unrealircd.h"

/**************** UTF8 HELPER FUNCTIONS START HERE *****************/

/* Operations on UTF-8 strings.
 * This part is taken from "glib" with the following copyright:
 * Copyright (C) 1999 Tom Tromey
 * Copyright (C) 2000 Red Hat, Inc.
 * Taken from the master snapshot on Oct 23, 2018, glib/gutf8.c.
 * The library uses LGPL 2.1. From what I understand this allows me to
 * use this code in a GPLv2-compatible way which fits the rest of
 * the UnrealIRCd project.
 *
 * Code stripped and converted heavily to fit in UnrealIRCd by
 * Bram Matthys ("Syzop") in 2019. Thanks to i <info@servx.org>
 * for all the directions and help with regards to UTF8 handling.
 *
 * Note that with UnrealIRCd, a char is always unsigned char,
 * which allows us to cut some corners and make more readable
 * code without 100 casts.
 */

#define VALIDATE_BYTE(mask, expect) \
  do {                              \
    if ((*p & (mask)) != (expect))  \
      goto error;                   \
  } while(0)

/* see IETF RFC 3629 Section 4 */

static const char *fast_validate(const char *str)
{
	const char *p;

	for (p = str; *p; p++)
	{
		if (*p >= 128)
		{
			const char *last;

			last = p;
			if (*p < 0xe0) /* 110xxxxx */
			{
				// ehm.. did you forget a ++p ? ;) or whatever
				if (*p < 0xc2)
				{
					goto error;
				}
			}
			else
			{
				if (*p < 0xf0) /* 1110xxxx */
				{
					switch (*p++ & 0x0f)
					{
						case 0:
							VALIDATE_BYTE(0xe0, 0xa0); /* 0xa0 ... 0xbf */
							break;
						case 0x0d:
							VALIDATE_BYTE(0xe0, 0x80); /* 0x80 ... 0x9f */
							break;
						default:
							VALIDATE_BYTE(0xc0, 0x80); /* 10xxxxxx */
					}
				}
				else if (*p < 0xf5) /* 11110xxx excluding out-of-range */
				{
					switch (*p++ & 0x07)
					{
						case 0:
							VALIDATE_BYTE(0xc0, 0x80); /* 10xxxxxx */
							if ((*p & 0x30) == 0)
								goto error;
							break;
						case 4:
							VALIDATE_BYTE(0xf0, 0x80); /* 0x80 ... 0x8f */
							break;
						default:
							VALIDATE_BYTE(0xc0, 0x80); /* 10xxxxxx */
					}
					p++;
					VALIDATE_BYTE(0xc0, 0x80); /* 10xxxxxx */
				}
				else
				{
					goto error;
				}
			}

			p++;
			VALIDATE_BYTE(0xc0, 0x80); /* 10xxxxxx */

			continue;

error:
			return last;
		}
	}

	return p;
}

/** Check if a string is valid UTF8.
 * @param str   The string to validate
 * @param end   Pointer to char *, as explained in notes below.
 * @returns 1 if the string is valid UTF8, 0 if not.
 * @notes The variable *end will be set to the first invalid UTF8 sequence.
 *        If no invalid UTF8 sequence is encountered then it points to the NUL byte.
 */
int unrl_utf8_validate(const char *str, const char **end)
{
	const char *p;

	p = fast_validate(str);

	if (end)
		*end = p;

	if (*p != '\0')
		return 0;
	else
		return 1;
}

/** Go backwards in a string until we are at the end of an UTF8 sequence.
 * Or more accurately: skip sequences that are part of an UTF8 sequence.
 * @param begin   The string to check
 * @param p       Where to start backtracking
 * @returns Byte that is not in the middle of an UTF8 sequence,
 *          or NULL if we reached the beginning and that isn't valid either.
 */
char *unrl_utf8_find_prev_char (const char *begin, const char *p)
{
	for (--p; p >= begin; --p)
	{
		if ((*p & 0xc0) != 0x80)
			return (char *)p;
	}
	return NULL;
}

/** Return a valid UTF8 string based on the input.
 * @param str The input string, with a maximum of 1024 bytes.
 * @retval Returns a valid UTF8 string (which may be sanitized
 *         or simply the original string if it was OK already)
 */
char *unrl_utf8_make_valid(const char *str)
{
	static char string[4096]; /* crazy, but lazy, max amplification is x3, so x4 is safe. */
	const char *remainder, *invalid;
	int remaining_bytes, valid_bytes, len;
	int replaced = 0; /**< UTF8 string needed replacement (was invalid) */

	if (!str)
		return NULL;

	len = strlen(str);

	if (len >= 1024)
		abort(); /* better safe than sorry */

	*string = '\0';
	remainder = str;
	remaining_bytes = len;

	while (remaining_bytes != 0)
	{
		if (unrl_utf8_validate(remainder, &invalid))
			break;
		replaced = 1;
		valid_bytes = invalid - remainder;

		strlncat(string, remainder, sizeof(string), valid_bytes); /*g_string_append_len(string, remainder, valid_bytes);*/
		strlcat(string, "\357\277\275", sizeof(string));

		remaining_bytes -= valid_bytes + 1;
		remainder = invalid + 1;
	}

	if (!replaced)
		return (char *)str; /* return original string (no changes needed) */

	/* If output size is too much for an IRC message then cut the string at
	 * the appropriate place (as in: not to cause invalid UTF8 due to
	 * cutting half-way a byte sequence).
	 */
	if (strlen(string) >= 510)
	{
		char *cut_at = unrl_utf8_find_prev_char(string, string+509);
		if (cut_at)
			*cut_at = '\0';
	}

	if (!unrl_utf8_validate(string, NULL))
		abort(); /* this should never happen, it means our conversion resulted in an invalid UTF8 string */

	return string;
}

/**************** END OF UTF8 HELPER FUNCTIONS *****************/

/** This is just for internal testing */
void utf8_test(void)
{
	char buf[1024];
	char *res;
	int cnt = 0;
	char *heapbuf; /* for strict OOB testing with ASan */

	while ((fgets(buf, sizeof(buf), stdin)))
	{
		stripcrlf(buf);
		heapbuf = strdup(buf);
		res = unrl_utf8_make_valid(heapbuf);
		if (heapbuf == res)
		{
			printf("    %s\n", res);
		} else {
			printf("[!] %s\n", res);
		}
		free(heapbuf);
	}
}
