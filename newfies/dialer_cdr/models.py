from django.db import models
from django.utils.translation import ugettext as _
from datetime import *
from dialer_gateway.models import Gateway
from dialer_campaign.models import Campaign, CampaignSubscriber
from voip_app.models import VoipApp
from common.intermediate_model_base_class import Model
from prefix_country.models import Prefix
from uuid import uuid1


CALLREQUEST_STATUS = (
    (1, u'PENDING'),
    (2, u'FAILURE'),
    (3, u'RETRY'), # spawn for retry
    (4, u'SUCCESS'),
    (5, u'ABORT'),
    (6, u'PAUSE'),
    (7, u'PROCESS'),
)

CALLREQUEST_TYPE = (
    (1, u'ORIGINAL'),
    (2, u'RETRY'),
)

VOIPCALL_DISPOSITION = (
    ('ANSWER', _('ANSWER')),
    ('BUSY', _('BUSY')),
    ('NOANSWER', _('NOANSWER')),
    ('CANCEL', _('CANCEL')),
    ('CONGESTION', _('CONGESTION')),
    ('CHANUNAVAIL', _('CHANUNAVAIL')),
    ('DONTCALL', _('DONTCALL')),
    ('TORTURE', _('TORTURE')),
    ('INVALIDARGS', _('INVALIDARGS')),
    ('NOROUTE', _('NOROUTE')),
    ('FORBIDDEN', _('FORBIDDEN')),
)


class CallRequestManager(models.Manager):
    """CallRequest Manager"""

    def get_pending_callrequest(self):
        """Return all the pending callrequest based on call time and status"""
        kwargs = {}
        kwargs['status'] = 1
        tday = datetime.now()
        kwargs['call_time__lte'] = datetime(tday.year, tday.month,
            tday.day, tday.hour, tday.minute, tday.second, tday.microsecond)
        
        #return Callrequest.objects.all()
        return Callrequest.objects.filter(**kwargs)

    
class Callrequest(Model):
    """This defines the call request, the dialer will read those new request
    and attempt to deliver the call

    **Attributes**:

        * ``request_uuid`` - Unique id
        * ``call_time`` - Total call time
        * ``call_type`` - Call type
        * ``status`` - Call request status
        * ``callerid`` - Caller ID
        * ``last_attempt_time`` -
        * ``result`` --
        * ``timeout`` -
        * ``timelimit`` -
        * ``extra_dial_string`` -
        * ``phone_number`` -
        * ``parent_callrequest`` -
        * ``extra_data`` -
        * ``hangup_cause`` -


    **Relationships**:

        * ``user`` - Foreign key relationship to the User model.\
        Each campaign assigned to User
        * ``voipapp`` - Foreign key relationship to the VoipApp model.\
        VoIP Application to use with this campaign
        * ``aleg_gateway`` - Foreign key relationship to the Gateway model.\
        Gateway to use to reach the subscriber
        * ``campaign_subscriber`` - Foreign key relationship to\
        CampaignSubscriber Model.
        * ``campaign`` - Foreign key relationship to the Campaign model.

    **Name of DB table**: dialer_callrequest
    """
    user = models.ForeignKey('auth.User')
    request_uuid = models.CharField(verbose_name=_("RequestUUID"),
                        default=uuid1(), db_index=True,
                        max_length=120, null=True, blank=True)
    call_time = models.DateTimeField(default=(lambda:datetime.now()))
    created_date = models.DateTimeField(auto_now_add=True, verbose_name='Date')
    updated_date = models.DateTimeField(auto_now=True)
    call_type = models.IntegerField(choices=CALLREQUEST_TYPE, default='1',
                verbose_name=_("Call Request Type"), blank=True, null=True)
    status = models.IntegerField(choices=CALLREQUEST_STATUS, default='1',
                blank=True, null=True)
    callerid = models.CharField(max_length=80, blank=True,
                verbose_name=_("CallerID"), help_text=_("CallerID used \
                to call the A-Leg"))
    phone_number = models.CharField(max_length=80)
    timeout = models.IntegerField(blank=True, default=30)
    timelimit = models.IntegerField(blank=True, default=3600)
    extra_dial_string = models.CharField(max_length=500, blank=True)

    campaign_subscriber = models.ForeignKey(CampaignSubscriber,
                null=True, blank=True,
                help_text=_("Campaign Subscriber related to this callrequest"))
    campaign = models.ForeignKey(Campaign, null=True, blank=True,
                help_text=_("Select Campaign"))
    aleg_gateway = models.ForeignKey(Gateway, null=True, blank=True,
                verbose_name="A-Leg Gateway",
                help_text=_("Select Gateway to use to reach the subscriber"))
    voipapp = models.ForeignKey(VoipApp, null=True, blank=True,
                verbose_name="VoIP Application", help_text=_("Select VoIP \
                Application to use with this campaign"))
    extra_data = models.CharField(max_length=120, blank=True,
                verbose_name=_("Extra Data"), help_text=_("Define the \
                additional data to pass to the application"))

    num_attempt = models.IntegerField(default=0)
    last_attempt_time = models.DateTimeField(null=True, blank=True)
    result = models.CharField(max_length=180, blank=True)
    hangup_cause = models.CharField(max_length=80, blank=True)

    # if the call fail, create a new pending instance and link them
    parent_callrequest = models.ForeignKey('self', null=True, blank=True)

    objects = CallRequestManager()

    class Meta:
        db_table = u'dialer_callrequest'
        verbose_name = _("Call Request")
        verbose_name_plural = _("Call Requests")

    def __unicode__(self):
            return u"%s [%s]" % (self.id, self.request_uuid)


class VoIPCall(models.Model):
    """This gives information of all the calls made with
    the carrier charges and revenue of each call.

    **Attributes**:

        * ``callid`` - callid of the phonecall
        * ``callerid`` - CallerID used to call out
        * ``phone_number`` - Phone number contacted
        * ``dialcode`` - Dialcode of the phonenumber
        * ``starting_date`` - Starting date of the call
        * ``duration`` - Duration of the call
        * ``billsec`` -
        * ``progresssec`` -
        * ``answersec`` -
        * ``waitsec`` -
        * ``disposition`` - Disposition of the call
        * ``hangup_cause`` -
        * ``hangup_cause_q850`` - 

    **Relationships**:

        * ``user`` - Foreign key relationship to the User model.
        * ``used_gateway`` - Foreign key relationship to the Gateway model.
        * ``callrequest`` - Foreign key relationship to the Callrequest model.

    **Name of DB table**: dialer_cdr
    """
    user = models.ForeignKey('auth.User', related_name='Call Sender')
    request_uuid = models.CharField(verbose_name=_("RequestUUID"),
                        default=uuid1(), db_index=True,
                        max_length=120, null=True, blank=True)
    used_gateway = models.ForeignKey(Gateway, null=True, blank=True)
    callrequest = models.ForeignKey(Callrequest, null=True, blank=True)
    callid = models.CharField(max_length=120, help_text=_("VoIP Call-ID"))
    callerid = models.CharField(max_length=120, verbose_name='CallerID')
    phone_number = models.CharField(max_length=120,
                    help_text=_(u'The international number of the \
                    recipient, without the leading +'), null=True, blank=True)
    dialcode = models.ForeignKey(Prefix, verbose_name="Destination", null=True,
                               blank=True, help_text=_("Select Prefix"))
    starting_date = models.DateTimeField(auto_now_add=True)
    duration = models.IntegerField(null=True, blank=True)
    billsec = models.IntegerField(null=True, blank=True)
    progresssec = models.IntegerField(null=True, blank=True)
    answersec = models.IntegerField(null=True, blank=True)
    waitsec = models.IntegerField(null=True, blank=True)
    disposition = models.CharField(choices=VOIPCALL_DISPOSITION, max_length=40, null=True, blank=True)
    hangup_cause = models.CharField(max_length=40, null=True, blank=True)
    hangup_cause_q850 = models.CharField(max_length=10, null=True, blank=True)


    def destination_name(self):
        """Return Recipient dialcode"""
        if self.dialcode is None:
            return "0"
        else:
            return self.dialcode.name

    def min_duration(self):
        """Return duration in min & sec"""
        self.duration = 120 # dilla test
        min = int(self.duration / 60)
        sec = int(self.duration % 60)
        return "%02d" % min + ":" + "%02d" % sec

    class Meta:
        db_table = 'dialer_cdr'
        verbose_name = _("VoIP Call")
        verbose_name_plural = _("VoIP Call")

    def __unicode__(self):
            return u"%s" % self.callid