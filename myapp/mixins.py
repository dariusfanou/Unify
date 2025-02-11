from django.utils.timezone import now
import humanize
import locale
from rest_framework import serializers

locale.setlocale(locale.LC_TIME, "fr_FR.UTF-8")

class TimeAgoMixin(serializers.Serializer):
    time_ago = serializers.SerializerMethodField()

    def get_time_ago(self, obj):
        now_time = now()
        diff = now_time - obj.created_at
        days = diff.days
        total_seconds = diff.total_seconds()

        if total_seconds < 60:
            return "À l’instant"
        elif total_seconds < 3600:
            minutes = round(total_seconds / 60)
            return f"Il y a {minutes} minute{'s' if minutes > 1 else ''}"
        elif total_seconds < 86400:
            hours = round(total_seconds / 3600)
            return f"Il y a {hours} heure{'s' if hours > 1 else ''}"
        elif days < 7:
            return f"Il y a {days} jour{'s' if days > 1 else ''}"
        elif days < 30:
            weeks = days // 7
            return f"Il y a {weeks} semaine{'s' if weeks > 1 else ''}"
        elif days < 365:
            months = days // 30
            return f"Il y a {months} mois"
        else:
            return obj.created_at.strftime("%d %B %Y")
